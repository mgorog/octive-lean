import OctiveLean.Value
import OctiveLean.Env
import OctiveLean.Error
import OctiveLean.AST

namespace OctiveLean

/-!
# Phase A — Pure Evaluation Monad

`PureM` replaces `IO` with `Id` at the base, making computations fully transparent
to Lean's kernel. This unlocks formal reasoning over expression evaluation,
control flow, and scoping without touching IO.

`EvalM = ExceptT OctaveError (StateT Env IO)`  — executable, IO-opaque
`PureM = ExceptT OctaveError (StateT Env Id)`  — provable, kernel-transparent

The connection: `liftPure : PureM α → EvalM α` is a monad homomorphism.
Any property proved about a `PureM` computation transfers to its `EvalM` lift.

IO-only operations (display, input, rand) remain in `EvalM`. When pure evaluation
encounters a builtin call, it throws a sentinel error so the IO layer can re-dispatch.
-/

abbrev PureM := ExceptT OctaveError (StateT Env Id)

def runPureM {α} (m : PureM α) (env : Env) : Except OctaveError α × Env :=
  StateT.run (ExceptT.run m) env

/-- Lift a pure computation into EvalM. Any `PureM` result transfers upward. -/
def liftPure {α} (m : PureM α) : ExceptT OctaveError (StateT Env IO) α := do
  let env ← get
  let (result, env') := runPureM m env
  set env'
  ExceptT.mk (pure result)

private def getPureEnv : PureM Env := get
private def setPureEnv (e : Env) : PureM Unit := set e
private def lookupVarP (name : String) : PureM Value := do
  let env ← getPureEnv
  match env.get name with
  | some v => return v
  | none =>
    match name with
    | "i" | "j" => return .complex 0.0 1.0
    | _ =>
    if env.getBuiltin name |>.isSome then return .fn (.builtin name)
    else throw (.nameError name)
private def setVarP (name : String) (val : Value) : PureM Unit :=
  modify (·.set name val)
private def arrFillP (n : Nat) (v : Float) : Array Float :=
  List.replicate n v |>.toArray

/-! Non-partial helpers — these CAN be unfolded by Lean's kernel for proofs. -/

def toFloatP (v : Value) : PureM Float :=
  match v.materialize with
  | .scalar f     => return f
  | .fscalar f    => return f
  | .complex r _  => return r
  | .integer iv   => return iv.toFloat
  | .boolean b    => return if b then 1.0 else 0.0
  | .matrix 1 1 d => return d[0]!
  | other => throw (.typeError s!"expected scalar, got {other.typeName}")

def evalLiteralP (lit : Literal) : Value :=
  match lit with
  | .float f => .scalar f
  | .int n   => .scalar (Float.ofInt n)
  | .str s   => .string s
  | .bool b  => .boolean b

def evalConstantP (name : String) : Option Value :=
  match name with
  | "true"  => some (.boolean true)
  | "false" => some (.boolean false)
  | "pi"    => some (.scalar 3.141592653589793)
  | "e"     => some (.scalar 2.718281828459045)
  | "Inf" | "inf" => some (.scalar (1.0 / 0.0))
  | "NaN" | "nan" => some (.scalar (0.0 / 0.0))
  | "eps"   => some (.scalar 2.220446049250313e-16)
  | _       => none

def isTruthy (v : Value) : Bool :=
  match v with
  | .boolean b  => b
  | .scalar f   => f != 0.0
  | .integer iv => iv.toFloat != 0.0
  | .empty      => false
  | _           => true

/-- Non-partial binary op dispatcher (dispatches to helpers, no recursion over AST). -/
private partial def ewiseOpP (op : Float → Float → Float) (a b : Value) : PureM Value :=
  match a.materialize, b.materialize with
  | .scalar x,        .scalar y        => return .scalar (op x y)
  | .scalar x,        .matrix r c d    => return .matrix r c (d.map (op x ·))
  | .matrix r c d,    .scalar y        => return .matrix r c (d.map (op · y))
  | .matrix r1 c1 d1, .matrix r2 c2 d2 =>
      if r1 == r2 && c1 == c2 then
        return .matrix r1 c1 (Array.zipWith (op · ·) d1 d2)
      else throw (.valueError s!"matrix size mismatch: {r1}×{c1} vs {r2}×{c2}")
  | .boolean b, v => ewiseOpP op (.scalar (if b then 1.0 else 0.0)) v
  | v, .boolean b => ewiseOpP op v (.scalar (if b then 1.0 else 0.0))
  | .integer iv, v => ewiseOpP op (.scalar iv.toFloat) v
  | v, .integer iv => ewiseOpP op v (.scalar iv.toFloat)
  | la, lb => throw (.typeError s!"cannot apply arithmetic to {la.typeName} and {lb.typeName}")

private def cmpOpP (op : Float → Float → Bool) (a b : Value) : PureM Value := do
  let x ← toFloatP a; let y ← toFloatP b
  return .boolean (op x y)

private def matMulP (r1 c1 : Nat) (d1 : Array Float)
    (r2 c2 : Nat) (d2 : Array Float) : PureM Value := do
  if c1 != r2 then
    throw (.valueError s!"matrix multiply: {r1}×{c1} * {r2}×{c2} incompatible")
  let out := Id.run do
    let mut o := arrFillP (r1 * c2) 0.0
    for i in List.range r1 do
      for j in List.range c2 do
        let mut s := 0.0
        for k in List.range c1 do
          s := s + d1[i * c1 + k]! * d2[k * c2 + j]!
        o := o.set! (i * c2 + j) s
    o
  return .matrix r1 c2 out

/-- Non-partial scalar binary op. Kernel-transparent: enables formal arithmetic proofs. -/
def evalBinOpScalarP (op : BinOp) (x y : Float) : PureM Value :=
  match op with
  | .add   => return .scalar (x + y)
  | .sub   => return .scalar (x - y)
  | .mul   => return .scalar (x * y)
  | .emul  => return .scalar (x * y)
  | .div   => return .scalar (x / y)
  | .ediv  => return .scalar (x / y)
  | .eldiv => return .scalar (y / x)
  | .ldiv  => return .scalar (y / x)
  | .epow  => return .scalar (Float.pow x y)
  | .pow   => return .scalar (Float.pow x y)
  | .lt    => return .boolean (x < y)
  | .le    => return .boolean (x <= y)
  | .gt    => return .boolean (x > y)
  | .ge    => return .boolean (x >= y)
  | .eq    => return .boolean (x == y)
  | .ne    => return .boolean (x != y)
  | .land  => return .boolean (x != 0.0 && y != 0.0)
  | .lor   => return .boolean (x != 0.0 || y != 0.0)
  | .band  => return .boolean (x != 0.0 && y != 0.0)
  | .bor   => return .boolean (x != 0.0 || y != 0.0)

def evalBinOpP (op : BinOp) (lv rv : Value) : PureM Value :=
  -- Non-partial scalar fast path: both sides materialize to .scalar
  match lv.materialize, rv.materialize with
  | .scalar x, .scalar y => evalBinOpScalarP op x y
  | lm, rm =>
    match op with
    | .add   => ewiseOpP (· + ·) lm rm
    | .sub   => ewiseOpP (· - ·) lm rm
    | .emul  => ewiseOpP (· * ·) lm rm
    | .ediv  => ewiseOpP (· / ·) lm rm
    | .eldiv => ewiseOpP (fun a b => b / a) lm rm
    | .epow  => ewiseOpP Float.pow lm rm
    | .mul   =>
        match lm, rm with
        | .scalar x, v           => ewiseOpP (· * ·) (.scalar x) v
        | v,         .scalar y   => ewiseOpP (· * ·) v (.scalar y)
        | .matrix r1 c1 d1, .matrix r2 c2 d2 => matMulP r1 c1 d1 r2 c2 d2
        | la, lb => throw (.typeError s!"cannot multiply {la.typeName} * {lb.typeName}")
    | .div   =>
        match rm with
        | .scalar y => ewiseOpP (· / ·) lm (.scalar y)
        | _ => throw (.typeError "matrix right-divide not yet implemented")
    | .ldiv  =>
        match lm with
        | .scalar x => ewiseOpP (fun a b => b / a) (.scalar x) rm
        | _ => throw (.typeError "matrix left-divide not yet implemented")
    | .pow   =>
        match lm, rm with
        | .scalar x, .scalar y => return .scalar (Float.pow x y)
        | _, _ => throw (.typeError "matrix power not yet implemented")
    | .lt    => cmpOpP (· < ·)  lm rm
    | .le    => cmpOpP (· <= ·) lm rm
    | .gt    => cmpOpP (· > ·)  lm rm
    | .ge    => cmpOpP (· >= ·) lm rm
    | .eq    => cmpOpP (· == ·) lm rm
    | .ne    => cmpOpP (· != ·) lm rm
    | .land  => do return .boolean ((← toFloatP lm) != 0.0 && (← toFloatP rm) != 0.0)
    | .lor   => do return .boolean ((← toFloatP lm) != 0.0 || (← toFloatP rm) != 0.0)
    | .band  => do return .boolean ((← toFloatP lm) != 0.0 && (← toFloatP rm) != 0.0)
    | .bor   => do return .boolean ((← toFloatP lm) != 0.0 || (← toFloatP rm) != 0.0)

private def indexValueP (v : Value) (args : Array Value) : PureM Value := do
  match v.materialize with
  | .matrix rows cols data =>
      if args.size == 1 then
        let i ← toFloatP args[0]!
        let idx := i.toUInt64.toNat - 1
        if idx < data.size then return .scalar data[idx]!
        else throw (.indexError s!"index {idx+1} out of bounds for {rows}×{cols}")
      else if args.size == 2 then
        let r ← toFloatP args[0]!; let c ← toFloatP args[1]!
        let ri := r.toUInt64.toNat - 1; let ci := c.toUInt64.toNat - 1
        if ri < rows && ci < cols then return .scalar data[ri * cols + ci]!
        else throw (.indexError s!"index ({ri+1},{ci+1}) out of bounds for {rows}×{cols}")
      else throw (.indexError "too many indices for matrix")
  | .string s =>
      let idx ← toFloatP args[0]!
      let i := idx.toUInt64.toNat - 1
      let chars := s.toList.toArray
      if i < chars.size then return .string (String.singleton chars[i]!)
      else throw (.indexError "string index out of bounds")
  | .cell _ _ data =>
      let i ← toFloatP args[0]!
      let idx := i.toUInt64.toNat - 1
      if idx < data.size then return data[idx]!
      else throw (.indexError "cell index out of bounds")
  | other => throw (.typeError s!"cannot index {other.typeName}")

private def matrixWriteP (base : Value) (idxs : Array Value) (newVal : Value) : PureM Value := do
  let toF : Value → PureM Float := fun v => match v.materialize with
    | .scalar f | .fscalar f => pure f
    | .integer iv => pure iv.toFloat
    | .boolean b  => pure (if b then 1.0 else 0.0)
    | .matrix 1 1 d => pure d[0]!
    | other => throw (.typeError s!"expected scalar index, got {other.typeName}")
  let toN : Value → PureM Nat := fun v => do return (← toF v).toUInt64.toNat
  let fv ← toF newVal
  match base.materialize, idxs with
  | .matrix r c d, #[iv] => do
      let i := (← toN iv) - 1
      if i < r * c then return Value.matrix r c (d.set! i fv)
      else
        let extended := d ++ arrFillP (i + 1 - d.size) 0.0
        return Value.matrix 1 (i + 1) (extended.set! i fv)
  | .matrix r c d, #[ri, ci] => do
      let row := (← toN ri) - 1; let col := (← toN ci) - 1
      let newR := max r (row + 1); let newC := max c (col + 1)
      let grown : Array Float :=
        if newR > r || newC > c then Id.run do
          let mut nd := arrFillP (newR * newC) 0.0
          for i in List.range r do
            for j in List.range c do
              nd := nd.set! (i * newC + j) d[i * c + j]!
          nd
        else d
      return Value.matrix newR newC (grown.set! (row * newC + col) fv)
  | .empty, #[iv] => do
      let i := (← toN iv) - 1
      return Value.matrix 1 (i + 1) ((arrFillP (i + 1) 0.0).set! i fv)
  | .empty, #[ri, ci] => do
      let row := (← toN ri) - 1; let col := (← toN ci) - 1
      return Value.matrix (row+1) (col+1)
        ((arrFillP ((row+1)*(col+1)) 0.0).set! (row*(col+1)+col) fv)
  | .scalar _, #[iv] => do
      if (← toN iv) == 1 then return newVal
      else throw (.indexError "scalar index out of bounds")
  | b, _ => throw (.typeError s!"indexed assignment on {b.typeName}")

/-! Mutual evaluator in PureM -/

mutual

  partial def evalExprP (e : Expr) : PureM Value := do
    match e with
    | .lit lit      => return evalLiteralP lit
    | .ident name   =>
        match evalConstantP name with
        | some v => return v
        | none   => lookupVarP name
    | .binop op l r =>
        let lv ← evalExprP l
        let rv ← evalExprP r
        evalBinOpP op lv rv
    | .unop op inner => evalUnOpP op inner
    | .range startE stepOpt stopE =>
        let sv ← toFloatP (← evalExprP startE)
        let ev ← toFloatP (← evalExprP stopE)
        match stepOpt with
        | some stepE => let stv ← toFloatP (← evalExprP stepE); return .range sv stv ev
        | none       => return .range sv 1.0 ev
    | .index expr args => do
        let fv ← evalExprP expr
        evalIndexP fv args
    | .dotIndex expr field =>
        let sv ← evalExprP expr
        match sv with
        | .struct fields =>
            match fields.find? (·.1 == field) with
            | some (_, v) => return v
            | none => throw (.nameError s!"struct has no field '{field}'")
        | other => throw (.typeError s!"cannot access field on {other.typeName}")
    | .dynField expr fieldExpr =>
        let sv ← evalExprP expr
        let fn ← evalExprP fieldExpr
        match fn, sv with
        | .string fname, .struct fields =>
            match fields.find? (·.1 == fname) with
            | some (_, v) => return v
            | none => throw (.nameError s!"no field '{fname}'")
        | _, _ => throw (.typeError "dynamic field name must be a string")
    | .matrix rows   => evalMatrixLiteralP rows
    | .cellArr rows  => evalCellLiteralP rows
    | .fnHandle name => return .fn (.handle name)
    | .anon params body =>
        let env ← getPureEnv
        let closure := env.currentScope.vars
        return .fn (.anon params body closure)
    | .endIdx   => throw (.runtimeError "'end' used outside indexing context")
    | .colonIdx => return .empty

  partial def evalUnOpP (op : UnOp) (e : Expr) : PureM Value := do
    let v ← evalExprP e
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
        | .scalar f     => return .boolean (f == 0.0)
        | .boolean b    => return .boolean (!b)
        | .matrix r c d => return .boolMat r c (d.map (· == 0.0))
        | other => throw (.typeError s!"cannot logically negate {other.typeName}")
    | .htranspose | .transpose =>
        match v.materialize with
        | .scalar f => return .scalar f
        | .matrix r c d =>
            let out := Id.run do
              let mut o := arrFillP (r * c) 0.0
              for i in List.range r do
                for j in List.range c do
                  o := o.set! (j * r + i) d[i * c + j]!
              o
            return .matrix c r out
        | other => throw (.typeError s!"cannot transpose {other.typeName}")

  partial def evalIndexP (fv : Value) (argExprs : Array Arg) : PureM Value := do
    match fv with
    | .fn funcVal => callFuncP funcVal (← evalArgsP argExprs)
    | _ =>
        let args ← evalArgValuesP argExprs fv
        indexValueP fv args

  partial def evalArgValuesP (args : Array Arg) (ctx : Value) : PureM (Array Value) := do
    let (rows, cols) := ctx.shape
    let total := rows * cols
    args.mapM fun a => match a with
      | .pos e  => evalExprP (substEndP e total)
      | .colon  =>
          let data := Value.rangeToArray 1.0 1.0 (Float.ofNat total)
          return .matrix 1 total data
      | .kw _ e => evalExprP e

  partial def evalArgsP (args : Array Arg) : PureM (Array Value) :=
    args.mapM fun a => match a with
      | .pos e  => evalExprP e
      | .colon  => return .empty
      | .kw _ e => evalExprP e

  partial def substEndP (e : Expr) (n : Nat) : Expr :=
    match e with
    | .endIdx       => .lit (.int n)
    | .binop op l r => .binop op (substEndP l n) (substEndP r n)
    | .unop op ie   => .unop op (substEndP ie n)
    | .range l s r  => .range (substEndP l n) (s.map (substEndP · n)) (substEndP r n)
    | other         => other

  /-- In pure mode, IO builtins throw a sentinel; the IO layer intercepts and re-dispatches. -/
  partial def callFuncP (fv : FuncVal) (args : Array Value) : PureM Value := do
    match fv with
    | .builtin name => throw (.runtimeError s!"__io_builtin:{name}")
    | .handle name =>
        let env ← getPureEnv
        match env.get name with
        | some (.fn fv') => callFuncP fv' args
        | some _         => throw (.typeError s!"'{name}' is not callable")
        | none           =>
            if env.getBuiltin name |>.isSome then
              throw (.runtimeError s!"__io_builtin:{name}")
            else throw (.nameError name)
    | .anon params body closure =>
        let env ← getPureEnv
        let mut frame : Array (String × Value) := closure
        for (p, a) in params.zip args do
          frame := (frame.filter (·.1 != p)).push (p, a)
        let newScope : Scope := { vars := frame, globals := #[], persist := #[], retVals := #[] }
        let innerEnv : Env := { env with stack := env.stack.push newScope }
        match runPureM (evalExprP body) innerEnv with
        | (.ok v, _)    => return v
        | (.error e, _) => throw e
    | .userDef uf =>
        let env ← getPureEnv
        let env' := env.pushFrame uf.retVals
        let mut envWithArgs := env'
        for (p, a) in uf.params.zip args do
          envWithArgs := envWithArgs.set p a
        for (k, v) in uf.closure do
          envWithArgs := envWithArgs.set k v
        let (funcResult, funcEnv) := runPureM (runBlockP uf.body) envWithArgs
        let (outerEnv, frame) := Env.popFrame funcEnv
        setPureEnv outerEnv
        let rets := uf.retVals.filterMap (frame.get ·)
        match funcResult with
        | .ok _ | .error .returnSignal => return rets[0]?.getD .empty
        | .error e => throw e

  partial def evalMatrixLiteralP (rows : Array (Array Expr)) : PureM Value := do
    if rows.isEmpty then return .empty
    let evaledRows ← rows.mapM (·.mapM evalExprP)
    let cols := (evaledRows[0]!).size
    if evaledRows.any (·.size != cols) then
      throw (.valueError "inconsistent row lengths in matrix literal")
    let data : Array Float ← evaledRows.foldlM (init := #[]) fun acc row => do
      row.foldlM (init := acc) fun acc' v => do
        match v.materialize with
        | .scalar f   => return acc'.push f
        | .integer iv => return acc'.push iv.toFloat
        | .boolean b  => return acc'.push (if b then 1.0 else 0.0)
        | other => throw (.typeError s!"cannot embed {other.typeName} in matrix literal")
    return .matrix evaledRows.size cols data

  partial def evalCellLiteralP (rows : Array (Array Expr)) : PureM Value := do
    if rows.isEmpty then return .cell 0 0 #[]
    let evaledRows ← rows.mapM (·.mapM evalExprP)
    let cols := (evaledRows[0]!).size
    let data := evaledRows.foldl (init := #[]) (· ++ ·)
    return .cell evaledRows.size cols data

  partial def runBlockP (stmts : Array Stmt) : PureM Unit :=
    stmts.forM evalStmtP

  /-- Pure statement evaluator. Output is suppressed; state changes are preserved. -/
  partial def evalStmtP (s : Stmt) : PureM Unit := do
    match s with
    | .exprS e _ =>
        let v ← evalExprP e
        match v with
        | .empty => pure ()
        | _      => setVarP "ans" v
    | .assign targets rhs _ =>
        let v ← evalExprP rhs
        if targets.size == 1 then
          setVarP targets[0]! v
        else
          match v with
          | .cell _ _ data =>
              for (i, t) in targets.toList.mapIdx (fun i t => (i, t)) do
                setVarP t (data[i]?.getD .empty)
          | _ =>
              setVarP targets[0]! v
              for t in targets.toList.tail do setVarP t .empty
    | .ifS cond thenB elseifs elseB =>
        let cv ← evalExprP cond
        if isTruthy cv then
          runBlockP thenB
        else
          let found ← elseifs.foldlM (init := false) fun done (c, b) => do
            if done then return true
            if isTruthy (← evalExprP c) then do runBlockP b; return true
            else return false
          unless found do
            match elseB with | some b => runBlockP b | none => return ()
    | .forS varName iter body =>
        let iv ← evalExprP iter
        let items := match iv.materialize with
          | .matrix 1 _ data => data.map Value.scalar
          | .matrix r c data =>
              Array.ofFn (n := c) fun j =>
                let col := Array.ofFn (n := r) fun i => data[i.val * c + j.val]!
                Value.matrix r 1 col
          | .empty  => #[]
          | other   => #[other]
        for item in items do
          setVarP varName item
          try runBlockP body
          catch
          | .breakSignal    => return ()
          | .continueSignal => continue
          | e               => throw e
    | .whileS cond body =>
        let rec whileLoop : PureM Unit := do
          if isTruthy (← evalExprP cond) then
            try runBlockP body; whileLoop
            catch
            | .breakSignal    => return ()
            | .continueSignal => whileLoop
            | e               => throw e
        whileLoop
    | .doUntil body cond =>
        let rec doLoop : PureM Unit := do
          try runBlockP body
          catch | .breakSignal => return () | .continueSignal => pure () | e => throw e
          unless isTruthy (← evalExprP cond) do doLoop
        doLoop
    | .returnS   => throw .returnSignal
    | .breakS    => throw .breakSignal
    | .continueS => throw .continueSignal
    | .funcDefS fd =>
        let env ← getPureEnv
        let uf := UserFunc.mk fd.name fd.params fd.retVals fd.body env.currentScope.vars
        setVarP fd.name (.fn (.userDef uf))
    | .switchS expr cases otherwise =>
        let v ← evalExprP expr
        let handled ← cases.foldlM (init := false) fun done (pat, body) => do
          if done then return true
          let pv ← evalExprP pat
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
          if isMatch then do runBlockP body; return true
          else return false
        unless handled do
          match otherwise with | some b => runBlockP b | none => return ()
    | .tryS body catchClause =>
        let err ← MonadExcept.tryCatch
          (do runBlockP body; return (none : Option OctaveError))
          (fun e => return some e)
        match err with
        | some .returnSignal | some .breakSignal | some .continueSignal => throw err.get!
        | some _ => match catchClause with | some (_, b) => runBlockP b | none => return ()
        | none => return ()
    | .indexAssign lhs rhs _ => do
        let newVal ← evalExprP rhs
        match lhs with
        | .dotIndex (.ident name) field => do
            let base ← lookupVarP name <|> return .struct #[]
            let newBase := match base with
              | .struct fs =>
                  match fs.findIdx? fun (k, _) => k == field with
                  | some i => Value.struct (fs.set! i (field, newVal))
                  | none   => Value.struct (fs.push (field, newVal))
              | _ => Value.struct #[(field, newVal)]
            setVarP name newBase
        | .index (.ident name) argExprs => do
            let idxs ← evalArgValuesP argExprs .empty
            let base ← lookupVarP name <|> return .empty
            let newBase ← matrixWriteP base idxs newVal
            setVarP name newBase
        | _ => throw (.runtimeError "unsupported LHS for indexed assignment")
    | .globalS names  => names.forM fun n => modify (·.declareGlobal n)
    | .persistS _     => return ()
    | .clearS names   =>
        modify fun env => names.foldl (fun e n => e.updateScope (·.del n)) env
    | .unwindS body cleanup =>
        let savedErr ← MonadExcept.tryCatch
          (do runBlockP body; return (none : Option OctaveError))
          (fun e => return some e)
        runBlockP cleanup
        match savedErr with | some e => throw e | none => return ()

end

/-!
## Provable lemmas about PureM

These hold because `PureM` uses `Id` as the base monad, making `runPureM`
reduce definitionally. The `partial def` mutual block is opaque; we work around
it by stating specific-case lemmas using `evalLiteralP` and `evalConstantP`,
which ARE non-partial and reducible.
-/

section PureMLemmas

/-- Literal evaluation never touches the environment. -/
@[simp] theorem toFloatP_scalar (f : Float) (env : Env) :
    runPureM (toFloatP (.scalar f)) env = (.ok f, env) := rfl

@[simp] theorem toFloatP_boolean_true (env : Env) :
    runPureM (toFloatP (.boolean true)) env = (.ok 1.0, env) := rfl

@[simp] theorem toFloatP_boolean_false (env : Env) :
    runPureM (toFloatP (.boolean false)) env = (.ok 0.0, env) := rfl

@[simp] theorem evalLiteralP_float (f : Float) :
    evalLiteralP (.float f) = .scalar f := rfl

@[simp] theorem evalLiteralP_int (n : Int) :
    evalLiteralP (.int n) = .scalar (Float.ofInt n) := rfl

@[simp] theorem evalLiteralP_str (s : String) :
    evalLiteralP (.str s) = .string s := rfl

@[simp] theorem evalLiteralP_bool (b : Bool) :
    evalLiteralP (.bool b) = .boolean b := rfl

/-- isTruthy is decidable and doesn't require IO. -/
@[simp] theorem isTruthy_boolean (b : Bool) : isTruthy (.boolean b) = b := rfl
@[simp] theorem isTruthy_empty : isTruthy .empty = false := rfl

-- Note: isTruthy (.scalar 0.0) = false is NOT provable by rfl because
-- Float.bne is not definitionally decidable in Lean 4's kernel.
-- Use native_decide for concrete Float goals:
theorem isTruthy_scalar_zero : isTruthy (.scalar 0.0) = false := by native_decide

/-- runPureM of a pure return is always (.ok v, env). -/
@[simp] theorem runPureM_return (v : α) (env : Env) :
    runPureM (return v : PureM α) env = (.ok v, env) := rfl

/-- evalBinOpP on two scalars routes through the non-partial evalBinOpScalarP. -/
@[simp] theorem evalBinOpP_scalar_eq (op : BinOp) (x y : Float) (env : Env) :
    runPureM (evalBinOpP op (.scalar x) (.scalar y)) env =
    runPureM (evalBinOpScalarP op x y) env := by
  simp [evalBinOpP, Value.materialize]

/-- Scalar addition is provable by kernel reduction (no axiom needed). -/
theorem evalBinOpP_add_scalars (x y : Float) (env : Env) :
    (runPureM (evalBinOpP .add (.scalar x) (.scalar y)) env).1 = .ok (.scalar (x + y)) := by
  simp [evalBinOpP, Value.materialize, evalBinOpScalarP]

/-- Scalar multiplication is provable by kernel reduction. -/
theorem evalBinOpP_mul_scalars (x y : Float) (env : Env) :
    (runPureM (evalBinOpP .mul (.scalar x) (.scalar y)) env).1 = .ok (.scalar (x * y)) := by
  simp [evalBinOpP, Value.materialize, evalBinOpScalarP]

/-- All scalar binary ops preserve the environment. -/
theorem evalBinOpP_scalar_preserves_env (op : BinOp) (x y : Float) (env : Env) :
    (runPureM (evalBinOpP op (.scalar x) (.scalar y)) env).2 = env := by
  simp [evalBinOpP, Value.materialize]
  cases op <;> simp [evalBinOpScalarP]

/-! Helper lemmas for the environment set/get roundtrip proofs -/

/-- Key-value list: updating the entry at the findIdx? position returns the new value. -/
private theorem List.findSome?_set_key
    {α : Type} {l : List (String × α)} {name : String} {val : α} {i : Nat}
    (hidx : l.findIdx? (fun kv => kv.1 == name) = some i) :
    (l.set i (name, val)).findSome? (fun kv => if kv.1 == name then some kv.2 else none)
    = some val := by
  induction l generalizing i with
  | nil => simp at hidx
  | cons head rest ih =>
    obtain ⟨k, v⟩ := head
    rw [List.findIdx?_cons] at hidx
    rcases h : k == name with _ | _
    · simp only [h] at hidx
      rcases Option.map_eq_some_iff.mp hidx with ⟨j, hj, rfl⟩
      simp only [List.set, List.findSome?_cons, h]; exact ih hj
    · have hi : i = 0 := by simp [h] at hidx; omega
      subst hi; simp [List.set]

/-- Scope set/get round-trip: setting a variable then getting it returns the new value. -/
private theorem scope_set_get (s : Scope) (name : String) (val : Value) :
    (s.set name val).get name = some val := by
  rcases h : s.vars.findIdx? (fun kv => kv.1 == name) with _ | ⟨i⟩
  · simp only [Scope.set, h]
    unfold Scope.get; simp only [Array.findSome?_push]
    have hnil : s.vars.findSome? (fun x : String × Value =>
        if (x.fst == name) = true then some x.snd else none) = none := by
      rw [Array.findSome?_eq_none_iff]
      intro kv hmem; simp [Array.findIdx?_eq_none_iff.mp h kv hmem]
    simp only [hnil, Option.none_or]; simp
  · simp only [Scope.set, h]
    unfold Scope.get
    rw [← Array.findSome?_toList, Array.set!_eq_setIfInBounds, Array.toList_setIfInBounds]
    apply List.findSome?_set_key
    rw [← List.findIdx?_toArray]; exact h

/-- Scope.set only updates `vars`; `globals` is unchanged. -/
private theorem scope_globals_set (s : Scope) (name : String) (val : Value) :
    (s.set name val).globals = s.globals := by
  simp only [Scope.set]; split <;> rfl

/-- After updateScope, currentScope equals the updated scope (requires non-empty stack). -/
private theorem currentScope_updateScope (env : Env) (f : Scope → Scope)
    (hne : 0 < env.stack.size) :
    (env.updateScope f).currentScope = f env.currentScope := by
  have hlt : env.stack.size - 1 < env.stack.size := Nat.sub_lt hne (by omega)
  have hemp : env.stack.isEmpty = false := by
    simp [Array.isEmpty_eq_false_iff]; intro heq; simp [heq] at hne
  have hset_back : (env.stack.set! (env.stack.size - 1) (f env.stack.back!)).back!
      = f env.stack.back! := by
    simp only [Array.back!, Array.set!_eq_setIfInBounds, Array.size_setIfInBounds,
               getElem!_def, Array.getElem?_setIfInBounds_self_of_lt hlt]
  simp only [Env.updateScope, Env.currentScope, hemp, Bool.false_eq_true, if_false]
  have hne2 : (env.stack.set! (env.stack.size - 1) (f env.stack.back!)).isEmpty = false := by
    simp [Array.set!_eq_setIfInBounds, Array.isEmpty_eq_false_iff]
    intro heq; simp [heq] at hne
  simp only [hne2, Bool.false_eq_true, if_false, hset_back]

/-- Environment set/get round-trip in local scope. -/
theorem env_set_get_roundtrip (env : Env) (name : String) (val : Value)
    (hg : env.currentScope.globals.contains name = false)
    (hne : 0 < env.stack.size) :
    (env.set name val).get name = some val := by
  have hset : env.set name val = env.updateScope (·.set name val) := by
    simp only [Env.set, hg, Bool.false_eq_true, if_false]
  rw [hset]
  have hcs := currentScope_updateScope env (·.set name val) hne
  unfold Env.get
  have hg' : (env.currentScope.set name val).globals.contains name = false := by
    rw [scope_globals_set]; exact hg
  simp only [hcs, hg', Bool.false_eq_true, if_false, scope_set_get]

/-- lookupVarP succeeds with the given value when env.get returns some. -/
private theorem runPureM_lookupVarP_some {val : Value} (name : String) (env : Env)
    (h : env.get name = some val) :
    (runPureM (lookupVarP name) env).1 = .ok val := by
  simp [runPureM, lookupVarP, getPureEnv, ExceptT.run, StateT.run,
        get, getThe, MonadStateOf.get, liftM, monadLift, MonadLift.monadLift,
        ExceptT.lift, Functor.map, ExceptT.mk, bind, ExceptT.bind, pure, ExceptT.pure,
        ExceptT.bindCont, StateT.map, StateT.get, StateT.bind, StateT.pure, h]

/-- setVarP then lookupVarP retrieves the value (local scope). -/
theorem setVar_lookup_roundtrip (name : String) (val : Value) (env : Env)
    (hg : env.currentScope.globals.contains name = false)
    (hne : 0 < env.stack.size) :
    (runPureM (do setVarP name val; lookupVarP name) env).1 = .ok val := by
  -- setVarP changes env to env.set name val (Id-monad definitional equality)
  show (runPureM (lookupVarP name) (env.set name val)).1 = .ok val
  exact runPureM_lookupVarP_some name _ (env_set_get_roundtrip env name val hg hne)

/-- liftPure homomorphism: pure ok results become EvalM ok results. -/
theorem liftPure_ok {α} (m : PureM α) (env : Env) (v : α)
    (h : (runPureM m env).1 = .ok v) :
    ∃ env', runPureM m env = (.ok v, env') :=
  ⟨(runPureM m env).2, Prod.ext h rfl⟩

end PureMLemmas

end OctiveLean
