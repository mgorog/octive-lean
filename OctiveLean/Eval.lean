import OctiveLean.Value
import OctiveLean.Env
import OctiveLean.Error
import OctiveLean.AST

namespace OctiveLean

/-! Interpreter monad -/

-- ExceptT on outside, StateT inside: state is preserved through exceptions.
-- This means break/continue signals don't roll back variable assignments.
abbrev EvalM := ExceptT OctaveError (StateT Env IO)

/-- Run an EvalM action; state is always returned even on error. -/
def runEvalM {α} (m : EvalM α) (env : Env) : IO (Except OctaveError α × Env) :=
  StateT.run (ExceptT.run m) env

private def getEnv : EvalM Env := get
private def setEnv (e : Env) : EvalM Unit := set e

/-- Look up a variable or throw nameError -/
private def lookupVar (name : String) : EvalM Value := do
  let env ← getEnv
  match env.get name with
  | some v => return v
  | none   =>
    -- predefined constants (can be shadowed by local variables)
    match name with
    | "i" | "j" => return .complex 0.0 1.0
    | _ =>
    if env.getBuiltin name |>.isSome then return .fn (.builtin name)
    else throw (.nameError name)

/-- Set a variable in the current scope -/
private def setVar (name : String) (val : Value) : EvalM Unit :=
  modify (·.set name val)

/-- Create an array filled with a constant value -/
private def arrFill (n : Nat) (v : Float) : Array Float :=
  List.replicate n v |>.toArray

/-- Coerce a Value to a Float scalar, or error -/
private def toFloat (v : Value) : EvalM Float :=
  match v.materialize with
  | .scalar f     => return f
  | .fscalar f    => return f
  | .complex r _  => return r
  | .integer iv   => return iv.toFloat
  | .boolean b    => return if b then 1.0 else 0.0
  | .matrix 1 1 d => return d[0]!
  | other => throw (.typeError s!"expected scalar, got {other.typeName}")

/-- Element-wise binary op on two Values (handles broadcast) -/
private partial def ewiseOp (op : Float → Float → Float) (a b : Value) : EvalM Value :=
  match a.materialize, b.materialize with
  | .scalar x,        .scalar y        => return .scalar (op x y)
  | .scalar x,        .matrix r c d    => return .matrix r c (d.map (op x ·))
  | .matrix r c d,    .scalar y        => return .matrix r c (d.map (op · y))
  | .matrix r1 c1 d1, .matrix r2 c2 d2 =>
      if r1 == r2 && c1 == c2 then
        return .matrix r1 c1 (Array.zipWith (op · ·) d1 d2)
      else throw (.valueError s!"matrix size mismatch: {r1}×{c1} vs {r2}×{c2}")
  | .boolean b, v => ewiseOp op (.scalar (if b then 1.0 else 0.0)) v
  | v, .boolean b => ewiseOp op v (.scalar (if b then 1.0 else 0.0))
  | .integer iv, v => ewiseOp op (.scalar iv.toFloat) v
  | v, .integer iv => ewiseOp op v (.scalar iv.toFloat)
  | la, lb => throw (.typeError s!"cannot apply arithmetic to {la.typeName} and {lb.typeName}")

private def zipArr (f : Float → Float → Float) (a b : Array Float) : Array Float :=
  Array.zipWith f a b

private def cmpOp (op : Float → Float → Bool) (a b : Value) : EvalM Value := do
  let x ← toFloat a; let y ← toFloat b
  return .boolean (op x y)

/-- Matrix multiply A(r1×c1) × B(r2×c2) -/
private def matMul (r1 c1 : Nat) (d1 : Array Float)
    (r2 c2 : Nat) (d2 : Array Float) : EvalM Value := do
  if c1 != r2 then
    throw (.valueError s!"matrix multiply: {r1}×{c1} * {r2}×{c2} incompatible")
  let out := Id.run do
    let mut o := arrFill (r1 * c2) 0.0
    for i in List.range r1 do
      for j in List.range c2 do
        let mut s := 0.0
        for k in List.range c1 do
          s := s + d1[i * c1 + k]! * d2[k * c2 + j]!
        o := o.set! (i * c2 + j) s
    o
  return .matrix r1 c2 out

private def evalBinOp (op : BinOp) (lv rv : Value) : EvalM Value :=
  match op with
  | .add  => ewiseOp (· + ·) lv rv
  | .sub  => ewiseOp (· - ·) lv rv
  | .emul => ewiseOp (· * ·) lv rv
  | .ediv => ewiseOp (· / ·) lv rv
  | .eldiv => ewiseOp (fun a b => b / a) lv rv
  | .epow => ewiseOp Float.pow lv rv
  | .mul  =>
      match lv.materialize, rv.materialize with
      | .scalar x, v           => ewiseOp (· * ·) (.scalar x) v
      | v,         .scalar y   => ewiseOp (· * ·) v (.scalar y)
      | .matrix r1 c1 d1, .matrix r2 c2 d2 => matMul r1 c1 d1 r2 c2 d2
      | la, lb => throw (.typeError s!"cannot multiply {la.typeName} * {lb.typeName}")
  | .div  =>
      match rv.materialize with
      | .scalar y => ewiseOp (· / ·) lv (.scalar y)
      | _ => throw (.typeError "matrix right-divide not yet implemented")
  | .ldiv =>
      match lv.materialize with
      | .scalar x => ewiseOp (fun a b => b / a) (.scalar x) rv
      | _ => throw (.typeError "matrix left-divide not yet implemented")
  | .pow  =>
      match lv.materialize, rv.materialize with
      | .scalar x, .scalar y => return .scalar (Float.pow x y)
      | _, _ => throw (.typeError "matrix power not yet implemented")
  | .lt   => cmpOp (· < ·)  lv rv
  | .le   => cmpOp (· <= ·) lv rv
  | .gt   => cmpOp (· > ·)  lv rv
  | .ge   => cmpOp (· >= ·) lv rv
  | .eq   => cmpOp (· == ·) lv rv
  | .ne   => cmpOp (· != ·) lv rv
  | .land => do return .boolean ((← toFloat lv) != 0.0 && (← toFloat rv) != 0.0)
  | .lor  => do return .boolean ((← toFloat lv) != 0.0 || (← toFloat rv) != 0.0)
  | .band => do return .boolean ((← toFloat lv) != 0.0 && (← toFloat rv) != 0.0)
  | .bor  => do return .boolean ((← toFloat lv) != 0.0 || (← toFloat rv) != 0.0)

/-- Index into a materialised Value with already-evaluated index values -/
private def indexValue (v : Value) (args : Array Value) : EvalM Value := do
  match v.materialize with
  | .matrix rows cols data =>
      if args.size == 1 then
        let i ← toFloat args[0]!
        let idx := i.toUInt64.toNat - 1
        if idx < data.size then return .scalar data[idx]!
        else throw (.indexError s!"index {idx+1} out of bounds for {rows}×{cols}")
      else if args.size == 2 then
        let r ← toFloat args[0]!; let c ← toFloat args[1]!
        let ri := r.toUInt64.toNat - 1; let ci := c.toUInt64.toNat - 1
        if ri < rows && ci < cols then return .scalar data[ri * cols + ci]!
        else throw (.indexError s!"index ({ri+1},{ci+1}) out of bounds for {rows}×{cols}")
      else throw (.indexError "too many indices for matrix")
  | .string s =>
      let idx ← toFloat args[0]!
      let i := idx.toUInt64.toNat - 1
      let chars := s.toList.toArray
      if i < chars.size then return .string (String.singleton chars[i]!)
      else throw (.indexError "string index out of bounds")
  | .cell _ _ data =>
      let i ← toFloat args[0]!
      let idx := i.toUInt64.toNat - 1
      if idx < data.size then return data[idx]!
      else throw (.indexError "cell index out of bounds")
  | other => throw (.typeError s!"cannot index {other.typeName}")

/-- Apply an indexed write: base[idxs] = newVal.  Handles 1D and 2D indexing. -/
private def matrixWrite (base : Value) (idxs : Array Value) (newVal : Value) : EvalM Value := do
  let toF : Value → EvalM Float := fun v => match v.materialize with
    | .scalar f | .fscalar f => pure f
    | .integer iv => pure iv.toFloat
    | .boolean b  => pure (if b then 1.0 else 0.0)
    | .matrix 1 1 d => pure d[0]!
    | other => throw (.typeError s!"expected scalar index, got {other.typeName}")
  let toN : Value → EvalM Nat := fun v => do return (← toF v).toUInt64.toNat
  let fv ← toF newVal
  match base.materialize, idxs with
  -- 1D linear index into existing matrix
  | .matrix r c d, #[iv] => do
      let i := (← toN iv) - 1
      if i < r * c then
        return Value.matrix r c (d.set! i fv)
      else
        let extended := d ++ arrFill (i + 1 - d.size) 0.0
        return Value.matrix 1 (i + 1) (extended.set! i fv)
  -- 2D index into existing matrix
  | .matrix r c d, #[ri, ci] => do
      let row := (← toN ri) - 1; let col := (← toN ci) - 1
      let newR := max r (row + 1); let newC := max c (col + 1)
      let grown : Array Float :=
        if newR > r || newC > c then Id.run do
          let mut nd := arrFill (newR * newC) 0.0
          for i in List.range r do
            for j in List.range c do
              nd := nd.set! (i * newC + j) d[i * c + j]!
          nd
        else d
      return Value.matrix newR newC (grown.set! (row * newC + col) fv)
  -- Creating a new vector from empty
  | .empty, #[iv] => do
      let i := (← toN iv) - 1
      return Value.matrix 1 (i + 1) ((arrFill (i + 1) 0.0).set! i fv)
  -- Creating a new matrix from empty
  | .empty, #[ri, ci] => do
      let row := (← toN ri) - 1; let col := (← toN ci) - 1
      return Value.matrix (row+1) (col+1) ((arrFill ((row+1)*(col+1)) 0.0).set! (row*(col+1)+col) fv)
  -- Scalar reassignment
  | .scalar _, #[iv] => do
      if (← toN iv) == 1 then return newVal
      else throw (.indexError "scalar index out of bounds")
  | b, _ => throw (.typeError s!"indexed assignment on {b.typeName}")

/-! Main evaluator — all mutually recursive functions go here -/

mutual

  partial def evalExpr (e : Expr) : EvalM Value := do
    match e with
    | .lit (.float f)  => return .scalar f
    | .lit (.int n)    => return .scalar (Float.ofInt n)
    | .lit (.str s)    => return .string s
    | .lit (.bool b)   => return .boolean b
    | .ident "true"    => return .boolean true
    | .ident "false"   => return .boolean false
    | .ident "pi"      => return .scalar 3.141592653589793
    | .ident "e"       => return .scalar 2.718281828459045
    | .ident "Inf"     => return .scalar (1.0 / 0.0)
    | .ident "inf"     => return .scalar (1.0 / 0.0)
    | .ident "NaN"     => return .scalar (0.0 / 0.0)
    | .ident "nan"     => return .scalar (0.0 / 0.0)
    | .ident "eps"     => return .scalar 2.220446049250313e-16
    | .ident name      => lookupVar name
    | .binop op l r    =>
        let lv ← evalExpr l
        let rv ← evalExpr r
        evalBinOp op lv rv
    | .unop op inner   => evalUnOp op inner
    | .range startE stepOpt stopE =>
        let sv ← toFloat (← evalExpr startE)
        let ev ← toFloat (← evalExpr stopE)
        match stepOpt with
        | some stepE => let stv ← toFloat (← evalExpr stepE); return .range sv stv ev
        | none       => return .range sv 1.0 ev
    | .index expr args => do
        let fv ← evalExpr expr
        evalIndex fv args
    | .dotIndex expr field =>
        let sv ← evalExpr expr
        match sv with
        | .struct fields =>
            match fields.find? (·.1 == field) with
            | some (_, v) => return v
            | none => throw (.nameError s!"struct has no field '{field}'")
        | other => throw (.typeError s!"cannot access field on {other.typeName}")
    | .dynField expr fieldExpr =>
        let sv ← evalExpr expr
        let fn ← evalExpr fieldExpr
        match fn, sv with
        | .string fname, .struct fields =>
            match fields.find? (·.1 == fname) with
            | some (_, v) => return v
            | none => throw (.nameError s!"no field '{fname}'")
        | _, _ => throw (.typeError "dynamic field name must be a string")
    | .matrix rows  => evalMatrixLiteral rows
    | .cellArr rows => evalCellLiteral rows
    | .fnHandle name => return .fn (.handle name)
    | .anon params body =>
        let env ← getEnv
        let closure := env.currentScope.vars
        return .fn (.anon params body closure)
    | .endIdx   => throw (.runtimeError "'end' used outside indexing context")
    | .colonIdx => return .empty

  partial def evalUnOp (op : UnOp) (e : Expr) : EvalM Value := do
    let v ← evalExpr e
    match op with
    | .neg =>
        match v.materialize with
        | .scalar f     => return .scalar (-f)
        | .matrix r c d => return .matrix r c (d.map (- ·))
        | .integer iv   => return .scalar (-iv.toFloat)
        | other => throw (.typeError s!"cannot negate {other.typeName}")
    | .uplus => return v
    | .lnot =>
        match v.materialize with
        | .scalar f   => return .boolean (f == 0.0)
        | .boolean b  => return .boolean (!b)
        | .matrix r c d => return .boolMat r c (d.map (· == 0.0))
        | other => throw (.typeError s!"cannot logically negate {other.typeName}")
    | .htranspose | .transpose =>
        match v.materialize with
        | .scalar f => return .scalar f
        | .matrix r c d =>
            let out := Id.run do
              let mut o := arrFill (r * c) 0.0
              for i in List.range r do
                for j in List.range c do
                  o := o.set! (j * r + i) d[i * c + j]!
              o
            return .matrix c r out
        | other => throw (.typeError s!"cannot transpose {other.typeName}")

  partial def evalIndex (fv : Value) (argExprs : Array Arg) : EvalM Value := do
    match fv with
    | .fn funcVal =>
        let args ← evalArgs argExprs
        callFunc funcVal args
    | _ =>
        let args ← evalArgValues argExprs fv
        indexValue fv args

  partial def evalArgValues (args : Array Arg) (ctx : Value) : EvalM (Array Value) := do
    let (rows, cols) := ctx.shape
    let total := rows * cols
    args.mapM fun a => match a with
      | .pos e  => evalExpr (substEnd e total)
      | .colon  =>
          let data := Value.rangeToArray 1.0 1.0 (Float.ofNat total)
          return .matrix 1 total data
      | .kw _ e => evalExpr e

  partial def evalArgs (args : Array Arg) : EvalM (Array Value) :=
    args.mapM fun a => match a with
      | .pos e  => evalExpr e
      | .colon  => return .empty
      | .kw _ e => evalExpr e

  partial def substEnd (e : Expr) (n : Nat) : Expr :=
    match e with
    | .endIdx       => .lit (.int n)
    | .binop op l r => .binop op (substEnd l n) (substEnd r n)
    | .unop op ie   => .unop op (substEnd ie n)
    | .range l s r  => .range (substEnd l n) (s.map (substEnd · n)) (substEnd r n)
    | other         => other

  partial def callFunc (fv : FuncVal) (args : Array Value) : EvalM Value := do
    match fv with
    | .builtin name =>
        let env ← getEnv
        match env.getBuiltin name with
        | some fn =>
            let results ← liftM (fn args)
            return results[0]?.getD .empty
        | none => throw (.nameError s!"builtin '{name}' not registered")
    | .handle name =>
        let env ← getEnv
        match env.get name with
        | some (.fn fv') => callFunc fv' args
        | some _         => throw (.typeError s!"'{name}' is not callable")
        | none           =>
            match env.getBuiltin name with
            | some fn =>
                let results ← liftM (fn args)
                return results[0]?.getD .empty
            | none => throw (.nameError name)
    | .anon params body closure =>
        let env ← getEnv
        let mut frame : Array (String × Value) := closure
        for (p, a) in params.zip args do
          frame := (frame.filter (·.1 != p)).push (p, a)
        let newScope : Scope := { vars := frame, globals := #[], persist := #[], retVals := #[] }
        let innerEnv : Env := { env with stack := env.stack.push newScope }
        let (anonResult, _) ← liftM (runEvalM (evalExpr body) innerEnv)
        match anonResult with
        | .ok v  => return v
        | .error e => throw e
    | .userDef uf =>
        let env ← getEnv
        let env' := env.pushFrame uf.retVals
        let mut envWithArgs := env'
        for (p, a) in uf.params.zip args do
          envWithArgs := envWithArgs.set p a
        for (k, v) in uf.closure do
          envWithArgs := envWithArgs.set k v
        let (funcResult, funcEnv) ← liftM (runEvalM (runBlock uf.body) envWithArgs)
        let finalEnv := match funcResult with
          | .ok _    => funcEnv
          | .error _ => funcEnv  -- state always preserved now
        let (outerEnv, frame) := Env.popFrame finalEnv
        modify fun _ => outerEnv
        let rets := uf.retVals.filterMap (frame.get ·)
        match funcResult with
        | .ok _ | .error .returnSignal => return rets[0]?.getD .empty
        | .error e => throw e

  partial def evalMatrixLiteral (rows : Array (Array Expr)) : EvalM Value := do
    if rows.isEmpty then return .empty
    let evaledRows ← rows.mapM (·.mapM evalExpr)
    let cols := (evaledRows[0]!).size
    if evaledRows.any (·.size != cols) then
      throw (.valueError "inconsistent row lengths in matrix literal")
    let numRows := evaledRows.size
    let data : Array Float ← evaledRows.foldlM (init := #[]) fun acc row => do
      row.foldlM (init := acc) fun acc' v => do
        match v.materialize with
        | .scalar f   => return acc'.push f
        | .integer iv => return acc'.push iv.toFloat
        | .boolean b  => return acc'.push (if b then 1.0 else 0.0)
        | other => throw (.typeError s!"cannot embed {other.typeName} in matrix literal")
    return .matrix numRows cols data

  partial def evalCellLiteral (rows : Array (Array Expr)) : EvalM Value := do
    if rows.isEmpty then return .cell 0 0 #[]
    let evaledRows ← rows.mapM (·.mapM evalExpr)
    let cols := (evaledRows[0]!).size
    let data := evaledRows.foldl (init := #[]) (· ++ ·)
    return .cell evaledRows.size cols data

  partial def runBlock (stmts : Array Stmt) : EvalM Unit :=
    stmts.forM evalStmt

  partial def evalStmt (s : Stmt) : EvalM Unit := do
    match s with
    | .exprS e silent =>
        let v ← evalExpr e
        unless silent do
          match v with
          | .empty => pure ()   -- void return: don't print
          | _ =>
              let name := match e with | .ident n => n | _ => "ans"
              setVar "ans" v
              liftM <| IO.println (v.display name)
    | .assign targets rhs silent =>
        let v ← evalExpr rhs
        if targets.size == 1 then
          setVar targets[0]! v
          unless silent do liftM <| IO.println (v.display targets[0]!)
        else
          match v with
          | .cell _ _ data =>
              for (i, t) in targets.toList.mapIdx (fun i t => (i, t)) do
                let vi := data[i]?.getD .empty
                setVar t vi
                unless silent do liftM <| IO.println (vi.display t)
          | _ =>
              setVar targets[0]! v
              for t in targets.toList.tail do setVar t .empty
    | .ifS cond thenB elseifs elseB =>
        let cv ← evalExpr cond
        let truthy := match cv with
          | .boolean b  => b | .scalar f => f != 0.0
          | .integer iv => iv.toFloat != 0.0 | .empty => false | _ => true
        if truthy then
          runBlock thenB
        else
          let found ← elseifs.foldlM (init := false) fun done (c, b) => do
            if done then return true
            let cv ← evalExpr c
            let t := match cv with | .boolean b => b | .scalar f => f != 0.0 | _ => true
            if t then do runBlock b; return true
            else return false
          unless found do
            match elseB with | some b => runBlock b | none => return ()
    | .forS varName iter body =>
        let iv ← evalExpr iter
        let items := match iv.materialize with
          | .matrix 1 _ data => data.map Value.scalar
          | .matrix r c data =>
              Array.ofFn (n := c) fun j =>
                let col := Array.ofFn (n := r) fun i => data[i.val * c + j.val]!
                Value.matrix r 1 col
          | .empty  => #[]
          | other   => #[other]
        for item in items do
          setVar varName item
          try runBlock body
          catch
          | .breakSignal    => return ()
          | .continueSignal => continue
          | e               => throw e
    | .whileS cond body =>
        let rec whileLoop : EvalM Unit := do
          let cv ← evalExpr cond
          let t := match cv with | .boolean b => b | .scalar f => f != 0.0 | _ => true
          if t then
            try runBlock body; whileLoop
            catch
            | .breakSignal    => return ()
            | .continueSignal => whileLoop
            | e               => throw e
        whileLoop
    | .doUntil body cond =>
        let rec doLoop : EvalM Unit := do
          try runBlock body
          catch | .breakSignal => return () | .continueSignal => pure () | e => throw e
          let cv ← evalExpr cond
          let t := match cv with | .boolean b => b | .scalar f => f != 0.0 | _ => true
          unless t do doLoop
        doLoop
    | .returnS   => throw .returnSignal
    | .breakS    => throw .breakSignal
    | .continueS => throw .continueSignal
    | .funcDefS fd =>
        let env ← getEnv
        let uf := UserFunc.mk fd.name fd.params fd.retVals fd.body env.currentScope.vars
        setVar fd.name (.fn (.userDef uf))
    | .switchS expr cases otherwise =>
        let v ← evalExpr expr
        let handled ← cases.foldlM (init := false) fun done (pat, body) => do
          if done then return true
          let pv ← evalExpr pat
          let isMatch := match v, pv with
            | .scalar x, .scalar y   => x == y
            | .string a, .string b   => a == b
            | .boolean a, .boolean b => a == b
            | _, .cell _ _ data =>
                data.any fun cv => match v, cv with
                  | .scalar x, .scalar y => x == y
                  | .string a, .string b => a == b
                  | _, _ => false
            | _, _ => false
          if isMatch then do runBlock body; return true
          else return false
        unless handled do
          match otherwise with | some b => runBlock b | none => return ()
    | .tryS body catchClause =>
        let err ← MonadExcept.tryCatch
          (do runBlock body; return (none : Option OctaveError))
          (fun e => return some e)
        match err with
        | some .returnSignal | some .breakSignal | some .continueSignal =>
            throw err.get!
        | some _ =>
            match catchClause with | some (_, b) => runBlock b | none => return ()
        | none => return ()
    | .indexAssign lhs rhs silent => do
        let newVal ← evalExpr rhs
        match lhs with
        -- Struct field: s.field = val
        | .dotIndex (.ident name) field => do
            let base ← lookupVar name <|> return .struct #[]
            let newBase := match base with
              | .struct fs =>
                  let idx := fs.findIdx? fun (k, _) => k == field
                  match idx with
                  | some i => Value.struct (fs.set! i (field, newVal))
                  | none   => Value.struct (fs.push (field, newVal))
              | _ => Value.struct #[(field, newVal)]
            setVar name newBase
            unless silent do liftM <| IO.println (newBase.display name)
        -- Index: A(i,j) = val  or  A(i) = val
        | .index (.ident name) argExprs => do
            let idxs ← evalArgValues argExprs .empty
            let base ← lookupVar name <|> return .empty
            let newBase ← matrixWrite base idxs newVal
            setVar name newBase
            unless silent do liftM <| IO.println (newBase.display name)
        | _ => throw (.runtimeError "unsupported LHS for indexed assignment")
    | .globalS names  => names.forM fun n => modify (·.declareGlobal n)
    | .persistS _     => return ()
    | .clearS names   =>
        modify fun env => names.foldl (fun e n => e.updateScope (·.del n)) env
    | .unwindS body cleanup =>
        let savedErr ← MonadExcept.tryCatch
          (do runBlock body; return (none : Option OctaveError))
          (fun e => return some e)
        runBlock cleanup
        match savedErr with | some e => throw e | none => return ()

end

/-- Pre-register top-level function definitions so they are available throughout. -/
private def hoistFuncDefs (stmts : Array Stmt) (env : Env) : Env :=
  stmts.foldl (fun e s => match s with
    | .funcDefS fd =>
        let uf := UserFunc.mk fd.name fd.params fd.retVals fd.body #[]
        e.set fd.name (.fn (.userDef uf))
    | _ => e) env

def runProgram (stmts : Array Stmt) (env : Env) : IO (Except OctaveError Env) := do
  let env := hoistFuncDefs stmts env
  let (result, env') ← runEvalM (runBlock stmts) env
  match result with
  | .ok ()  => return .ok env'
  | .error e => return .error e

end OctiveLean
