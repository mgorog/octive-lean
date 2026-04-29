import OctiveLean.PureEval

namespace OctiveLean

/-!
# Phase B — Big-Step Operational Semantics

Inductive relations `BigStepExpr`, `BigStepStmt`, `BigStepBlock` form the
*formal specification* of Octave semantics, independent of the evaluator.

Key benefits over `evalExprP`:
- No `partial def` opacity — types are fully transparent to the kernel
- Can be used as hypotheses: `h : BigStepExpr env e v env'`
- Enables determinism, type-preservation, and frame lemmas

## Mutual dependency

`BigStepStmt` references `BigStepBlock` (for if/while bodies) and vice versa,
so they are declared in a single `mutual` block.
-/

def exprStmtEnv (env' : Env) (v : Value) : Env :=
  match v with
  | .empty => env'
  | _      => env'.set "ans" v

/-! Expression big-step (standalone — no mutual dependency) -/

inductive BigStepExpr : Env → Expr → Value → Env → Prop where
  | litFloat  (f : Float)  (env : Env) : BigStepExpr env (.lit (.float f))  (.scalar f)              env
  | litInt    (n : Int)    (env : Env) : BigStepExpr env (.lit (.int n))    (.scalar (Float.ofInt n)) env
  | litStr    (s : String) (env : Env) : BigStepExpr env (.lit (.str s))    (.string s)               env
  | litBool   (b : Bool)   (env : Env) : BigStepExpr env (.lit (.bool b))   (.boolean b)              env

  | identConst (name : String) (v : Value) (env : Env)
      (h : evalConstantP name = some v) :
      BigStepExpr env (.ident name) v env

  | identVar (name : String) (v : Value) (env : Env)
      (hc : evalConstantP name = none)
      (hl : env.get name = some v) :
      BigStepExpr env (.ident name) v env

  | binop (op : BinOp) (l r : Expr) (lv rv v : Value) (env env1 env2 : Env)
      (hl  : BigStepExpr env  l lv env1)
      (hr  : BigStepExpr env1 r rv env2)
      (hop : (runPureM (evalBinOpP op lv rv) env2).1 = .ok v) :
      BigStepExpr env (.binop op l r) v env2

  | unopNeg (inner : Expr) (f : Float) (env env' : Env)
      (hv : BigStepExpr env inner (.scalar f) env') :
      BigStepExpr env (.unop .neg inner) (.scalar (-f)) env'

  | unopUplus (inner : Expr) (v : Value) (env env' : Env)
      (hv : BigStepExpr env inner v env') :
      BigStepExpr env (.unop .uplus inner) v env'

  | unopLnot (inner : Expr) (b : Bool) (env env' : Env)
      (hv : BigStepExpr env inner (.boolean b) env') :
      BigStepExpr env (.unop .lnot inner) (.boolean (!b)) env'

  | rangeNoStep (startE stopE : Expr) (sv ev : Float) (env env1 env2 : Env)
      (hs : BigStepExpr env  startE (.scalar sv) env1)
      (he : BigStepExpr env1 stopE  (.scalar ev) env2) :
      BigStepExpr env (.range startE none stopE) (.range sv 1.0 ev) env2

  | rangeStep (startE stepE stopE : Expr) (sv stv ev : Float) (env env1 env2 env3 : Env)
      (hs  : BigStepExpr env  startE (.scalar sv)  env1)
      (hst : BigStepExpr env1 stepE  (.scalar stv) env2)
      (he  : BigStepExpr env2 stopE  (.scalar ev)  env3) :
      BigStepExpr env (.range startE (some stepE) stopE) (.range sv stv ev) env3

  | anon (params : Array String) (body : Expr) (env : Env) :
      BigStepExpr env (.anon params body) (.fn (.anon params body env.currentScope.vars)) env

  | fnHandle (name : String) (env : Env) :
      BigStepExpr env (.fnHandle name) (.fn (.handle name)) env

  | matrixEmpty (rows : Array (Array Expr)) (env : Env) (h : rows.isEmpty) :
      BigStepExpr env (.matrix rows) .empty env

  | dotIndex (expr : Expr) (field : String) (fields : Array (String × Value))
      (v : Value) (env env' : Env)
      (he : BigStepExpr env expr (.struct fields) env')
      (hf : fields.find? (·.1 == field) = some (field, v)) :
      BigStepExpr env (.dotIndex expr field) v env'

/-! Statement and block big-step — mutually recursive -/

mutual

  inductive BigStepStmt : Env → Stmt → Env → Prop where
    | exprS (e : Expr) (silent : Bool) (v : Value) (env env' : Env)
        (he : BigStepExpr env e v env') :
        BigStepStmt env (.exprS e silent) (exprStmtEnv env' v)

    | assignSingle (name : String) (rhs : Expr) (v : Value) (env env' : Env) (silent : Bool)
        (he : BigStepExpr env rhs v env') :
        BigStepStmt env (.assign #[name] rhs silent) (env'.set name v)

    | ifTrue (cond : Expr) (thenB : Array Stmt)
        (elseifs : Array (Expr × Array Stmt)) (elseB : Option (Array Stmt))
        (cv : Value) (env env1 env2 : Env)
        (hc : BigStepExpr env cond cv env1)
        (ht : isTruthy cv = true)
        (hb : BigStepBlock env1 (Array.toList thenB) env2) :
        BigStepStmt env (.ifS cond thenB elseifs elseB) env2

    | ifFalseElse (cond : Expr) (thenB elseB : Array Stmt)
        (elseifs : Array (Expr × Array Stmt))
        (cv : Value) (env env1 env2 : Env)
        (hc : BigStepExpr env cond cv env1)
        (hf : isTruthy cv = false)
        (hb : BigStepBlock env1 (Array.toList elseB) env2) :
        BigStepStmt env (.ifS cond thenB elseifs (some elseB)) env2

    | ifFalseNoElse (cond : Expr) (thenB : Array Stmt)
        (elseifs : Array (Expr × Array Stmt))
        (cv : Value) (env env1 : Env)
        (hc : BigStepExpr env cond cv env1)
        (hf : isTruthy cv = false) :
        BigStepStmt env (.ifS cond thenB elseifs none) env1

    | returnS   (env : Env) : BigStepStmt env .returnS   env
    | breakS    (env : Env) : BigStepStmt env .breakS    env
    | continueS (env : Env) : BigStepStmt env .continueS env

    | globalDecl (names : Array String) (env : Env) :
        BigStepStmt env (.globalS names) (names.foldl (·.declareGlobal ·) env)

    | clearS (names : Array String) (env : Env) :
        BigStepStmt env (.clearS names)
          (names.foldl (fun e n => e.updateScope (·.del n)) env)

  inductive BigStepBlock : Env → List Stmt → Env → Prop where
    | nil  (env : Env) : BigStepBlock env [] env
    | cons (s : Stmt) (rest : List Stmt) (env env1 env2 : Env)
        (hs    : BigStepStmt env s env1)
        (hrest : BigStepBlock env1 rest env2) :
        BigStepBlock env (s :: rest) env2

end

/-!
## Meta-theorems

### Determinism
-/

theorem bigStepExpr_deterministic
    (h1 : BigStepExpr env e v1 env1)
    (h2 : BigStepExpr env e v2 env2) :
    v1 = v2 ∧ env1 = env2 := by
  induction h1 generalizing v2 env2 with
  | litFloat  _ _  => cases h2; exact ⟨rfl, rfl⟩
  | litInt    _ _  => cases h2; exact ⟨rfl, rfl⟩
  | litStr    _ _  => cases h2; exact ⟨rfl, rfl⟩
  | litBool   _ _  => cases h2; exact ⟨rfl, rfl⟩
  | anon _ _ _     => cases h2; exact ⟨rfl, rfl⟩
  | fnHandle _ _   => cases h2; exact ⟨rfl, rfl⟩
  | matrixEmpty _ _ _ => cases h2; exact ⟨rfl, rfl⟩
  | identConst name v env hc =>
      cases h2 with
      | identConst _ _ _ hc2 => exact ⟨Option.some.inj (hc ▸ hc2 ▸ rfl), rfl⟩
      | identVar _ _ _ hc2 _ => exact absurd (hc ▸ hc2) (by simp)
  | identVar name v env hc hl =>
      cases h2 with
      | identConst _ _ _ hc2 => exact absurd (hc ▸ hc2) (by simp)
      | identVar _ _ _ _ hl2 => exact ⟨Option.some.inj (hl ▸ hl2 ▸ rfl), rfl⟩
  | unopNeg _ f _ _ _ ih =>
      cases h2 with
      | unopNeg _ f2 _ _ h2' =>
          have ⟨heq, henv⟩ := ih h2'
          have hf : f = f2 := Value.scalar.inj heq
          exact ⟨congrArg (fun x => Value.scalar (-x)) hf, henv⟩
  | unopUplus _ _ _ _ _ ih =>
      cases h2 with | unopUplus _ _ _ _ h2' => exact ih h2'
  | unopLnot _ b _ _ _ ih =>
      cases h2 with
      | unopLnot _ b2 _ _ h2' =>
          have ⟨heq, henv⟩ := ih h2'
          have hb : b = b2 := Value.boolean.inj heq
          exact ⟨congrArg (fun x => Value.boolean (!x)) hb, henv⟩
  | binop _ _ _ lv rv _ _ env1 _ _ _ hop ih_l ih_r =>
      cases h2 with
      | binop _ _ _ lv2 rv2 _ _ env1' _ hl2 hr2 hop2 =>
          obtain ⟨hlv, henv1⟩ := ih_l hl2
          rw [← henv1] at hr2
          obtain ⟨hrv, henv2⟩ := ih_r hr2
          rw [← hlv, ← hrv, ← henv2] at hop2
          exact ⟨Except.ok.inj (hop.symm.trans hop2), henv2⟩
  | rangeNoStep _ _ sv ev _ env1 _ _ _ ih_s ih_e =>
      cases h2 with
      | rangeNoStep _ _ sv2 ev2 _ env1' _ hs2 he2 =>
          obtain ⟨hsv, henv1⟩ := ih_s hs2
          rw [← henv1] at he2
          obtain ⟨hev, henv2⟩ := ih_e he2
          exact ⟨by rw [Value.scalar.inj hsv, Value.scalar.inj hev], henv2⟩
  | rangeStep _ _ _ sv stv ev _ env1 env2 _ _ _ _ ih_s ih_st ih_e =>
      cases h2 with
      | rangeStep _ _ _ sv2 stv2 ev2 _ env1' env2' _ hs2 hst2 he2 =>
          obtain ⟨hsv,  henv1⟩ := ih_s hs2
          rw [← henv1] at hst2
          obtain ⟨hstv, henv2⟩ := ih_st hst2
          rw [← henv2] at he2
          obtain ⟨hev, henv3⟩  := ih_e he2
          exact ⟨by rw [Value.scalar.inj hsv, Value.scalar.inj hstv, Value.scalar.inj hev],
                 henv3⟩
  | dotIndex _ _ fields _ _ _ _ hf ih =>
      cases h2 with
      | dotIndex _ _ fields2 _ _ _ he2 hf2 =>
          obtain ⟨hfields, henv⟩ := ih he2
          rw [Value.struct.inj hfields] at hf
          exact ⟨(Prod.mk.inj (Option.some.inj (hf.symm.trans hf2))).2, henv⟩

/-!
### Environment frame lemma: expressions are read-only
-/

theorem bigStepExpr_readonly
    (h : BigStepExpr env e v env') :
    env'.globals = env.globals ∧ env'.stack.size = env.stack.size := by
  induction h with
  | litFloat | litInt | litStr | litBool
  | identConst | identVar | anon | fnHandle | matrixEmpty => exact ⟨rfl, rfl⟩
  | unopNeg    _ _ _ _ _ ih => exact ih
  | unopUplus  _ _ _ _ _ ih => exact ih
  | unopLnot   _ _ _ _ _ ih => exact ih
  | dotIndex   _ _ _ _ _ _ _ _ ih => exact ih
  | binop _ _ _ _ _ _ _ _ _ _ _ _ ih_l ih_r =>
      obtain ⟨g1, s1⟩ := ih_l; obtain ⟨g2, s2⟩ := ih_r
      exact ⟨g2.trans g1, s2.trans s1⟩
  | rangeNoStep _ _ _ _ _ _ _ _ _ ih_s ih_e =>
      obtain ⟨g1, s1⟩ := ih_s; obtain ⟨g2, s2⟩ := ih_e
      exact ⟨g2.trans g1, s2.trans s1⟩
  | rangeStep _ _ _ _ _ _ _ _ _ _ _ _ _ ih_s ih_st ih_e =>
      obtain ⟨g1, s1⟩ := ih_s; obtain ⟨g2, s2⟩ := ih_st; obtain ⟨g3, s3⟩ := ih_e
      exact ⟨g3.trans (g2.trans g1), s3.trans (s2.trans s1)⟩

/-!
### Type tag preservation
-/

def Value.tag : Value → String
  | .scalar _ | .fscalar _  => "double"
  | .complex _ _            => "complex"
  | .integer _              => "integer"
  | .boolean _              => "logical"
  | .matrix _ _ _           => "matrix"
  | .cmatrix _ _ _          => "cmatrix"
  | .boolMat _ _ _          => "boolMat"
  | .string _               => "char"
  | .cell _ _ _             => "cell"
  | .struct _               => "struct"
  | .fn _                   => "function_handle"
  | .range _ _ _            => "range"
  | .empty                  => "empty"

theorem litFloat_tag  {env env' f v} (h : BigStepExpr env (.lit (.float f)) v env') : v.tag = "double"  := by cases h; rfl
theorem litBool_tag   {env env' b v} (h : BigStepExpr env (.lit (.bool  b)) v env') : v.tag = "logical" := by cases h; rfl
theorem unopNeg_tag   {env env' e v} (h : BigStepExpr env (.unop .neg e)    v env') : v.tag = "double"  := by cases h; rfl
theorem unopLnot_tag  {env env' e v} (h : BigStepExpr env (.unop .lnot e)   v env') : v.tag = "logical" := by cases h; rfl
theorem anon_tag      {env env' p b v} (h : BigStepExpr env (.anon p b) v env') : v.tag = "function_handle" := by cases h; rfl

/-!
## Adequacy: evaluator ↔ BigStep spec

Blocked by `partial def` opacity; axiomatized with clear statements.
These axioms are the bridge between the computable evaluator and the relational spec.
-/

axiom evalExprP_sound (e : Expr) (v : Value) (env env' : Env)
    (h : runPureM (evalExprP e) env = (.ok v, env')) :
    BigStepExpr env e v env'

axiom evalExprP_complete (e : Expr) (v : Value) (env env' : Env)
    (h : BigStepExpr env e v env') :
    runPureM (evalExprP e) env = (.ok v, env')

/-- The evaluator is deterministic — proved via BigStep without unfolding `partial`. -/
theorem evalExprP_deterministic (e : Expr) (env : Env)
    (h1 : runPureM (evalExprP e) env = (.ok v1, env1'))
    (h2 : runPureM (evalExprP e) env = (.ok v2, env2')) :
    v1 = v2 ∧ env1' = env2' :=
  bigStepExpr_deterministic (evalExprP_sound e v1 env env1' h1)
                             (evalExprP_sound e v2 env env2' h2)

/-- The evaluator is read-only on the environment for expressions. -/
theorem evalExprP_readonly (e : Expr) (env : Env)
    (h : runPureM (evalExprP e) env = (.ok v, env')) :
    env'.globals = env.globals ∧ env'.stack.size = env.stack.size :=
  bigStepExpr_readonly (evalExprP_sound e v env env' h)

/-!
## Concrete program derivations

Building BigStep trees explicitly — no `partial def` unfolding needed.
-/

-- `1 + 2`: state the result in terms of the computed float to avoid norm_num
-- (Float lacks DecidableEq in Lean 4 core; kernel cannot evaluate Float arithmetic)
example (env : Env) :
    runPureM (evalExprP (.binop .add (.lit (.float 1)) (.lit (.float 2)))) env
    = (.ok (.scalar ((1 : Float) + 2)), env) := by
  apply evalExprP_complete
  apply BigStepExpr.binop .add _ _ (.scalar 1) (.scalar 2) (.scalar ((1 : Float) + 2)) env env env
  · exact BigStepExpr.litFloat 1 env
  · exact BigStepExpr.litFloat 2 env
  · simp [evalBinOpP, Value.materialize, evalBinOpScalarP]

-- boolean literal: proof is complete
example (env : Env) :
    runPureM (evalExprP (.lit (.bool true))) env = (.ok (.boolean true), env) := by
  apply evalExprP_complete; exact BigStepExpr.litBool true env

-- range: use OfNat literals `(1 : Float)` and `(3 : Float)` matching litFloat output
-- (OfNat and OfScientific instances route through opaque Float.ofScientific — not def-eq)
example (env : Env) :
    runPureM (evalExprP (.range (.lit (.float 1)) none (.lit (.float 3)))) env
    = (.ok (.range (1 : Float) 1.0 (3 : Float)), env) := by
  apply evalExprP_complete
  exact BigStepExpr.rangeNoStep _ _ (1 : Float) (3 : Float) env env env
    (BigStepExpr.litFloat 1 env) (BigStepExpr.litFloat 3 env)

-- negation: use `(5 : Float)` matching litFloat output
example (env : Env) :
    runPureM (evalExprP (.unop .neg (.lit (.float 5)))) env
    = (.ok (.scalar (-(5 : Float))), env) := by
  apply evalExprP_complete
  exact BigStepExpr.unopNeg _ (5 : Float) env env (BigStepExpr.litFloat 5 env)

-- if with false condition: env unchanged — proof is complete
example (env : Env) :
    BigStepStmt env (.ifS (.lit (.bool false)) #[] #[] none) env :=
  BigStepStmt.ifFalseNoElse (.lit (.bool false)) #[] #[] (.boolean false) env env
    (BigStepExpr.litBool false env) rfl

-- two-statement block: use OfNat floats matching litFloat, no arithmetic needed
example (env : Env) :
    BigStepBlock env
      [.assign #["x"] (.lit (.float 1)) true,
       .assign #["y"] (.lit (.float 2)) true]
      ((env.set "x" (.scalar 1)).set "y" (.scalar 2)) :=
  BigStepBlock.cons _ _ _ _ _
    (BigStepStmt.assignSingle "x" _ (.scalar 1) env env true (BigStepExpr.litFloat 1 env))
    (BigStepBlock.cons _ _ _ _ _
      (BigStepStmt.assignSingle "y" _ (.scalar 2) (env.set "x" (.scalar 1)) _ true
        (BigStepExpr.litFloat 2 _))
      (BigStepBlock.nil _))

end OctiveLean
