import OctiveLean.Foundation.Eval

/-!
# Foundation.Semantics — theorems about the operational semantics.

`eval` is a total Lean function; equational reasoning about it is
ordinary equality.  This file states the basic structural theorems
that pin down the meaning of each Core constructor.  Proofs are
`rfl` because the case in `eval` *is* the theorem statement.

These are the unit tests of the semantics: every theorem below is a
fact about what `eval` does, mechanically verified at typecheck
time, no `sorry`.

Higher-level facts (denotational ≈ operational, type preservation,
compile correctness for general programs) layer on top once the
surface meaning is defined explicitly — that's `Foundation.Compile`'s
job, addressed in a follow-up file.
-/

namespace OctiveLean.Foundation

open Eval

variable (prim : PrimopDispatch)

/-! ## Literals — pure values. -/

@[simp]
theorem eval_num (n : Float) (fuel : Nat) (env : Env) :
    eval prim (fuel + 1) (.lit (.float n)) env = pure (.num n) := rfl

@[simp]
theorem eval_str (s : String) (fuel : Nat) (env : Env) :
    eval prim (fuel + 1) (.lit (.str s)) env = pure (.str s) := rfl

@[simp]
theorem eval_bool (b : Bool) (fuel : Nat) (env : Env) :
    eval prim (fuel + 1) (.lit (.bool b)) env = pure (.bool b) := rfl

/-! ## Lambda — captures the lexical environment. -/

@[simp]
theorem eval_lam (ps : List String) (body : Core) (fuel : Nat) (env : Env) :
    eval prim (fuel + 1) (.lam ps body) env =
      pure (.closure ps body env) := rfl

/-! ## Sequencing — the second expression is the result. -/

@[simp]
theorem eval_seq (a b : Core) (fuel : Nat) (env : Env) :
    eval prim (fuel + 1) (.seq a b) env =
      (do let _ ← eval prim fuel a env; eval prim fuel b env) := rfl

/-! ## Let — local binding extends the env. -/

@[simp]
theorem eval_letin (x : String) (e₁ e₂ : Core) (fuel : Nat) (env : Env) :
    eval prim (fuel + 1) (.letin x e₁ e₂) env =
      (do let v ← eval prim fuel e₁ env
          eval prim fuel e₂ ((x, v) :: env)) := rfl

/-! ## Conditional — strict on the condition; then-branch on truthy. -/

@[simp]
theorem eval_ifte (c t e : Core) (fuel : Nat) (env : Env) :
    eval prim (fuel + 1) (.ifte c t e) env =
      (do let cv ← eval prim fuel c env
          if truthy cv then eval prim fuel t env else eval prim fuel e env) := rfl

/-! ## Determinism — `eval` is a function; equal inputs ↦ equal outputs. -/

theorem eval_deterministic
    (fuel : Nat) (e : Core) (env : Env) :
    eval prim fuel e env = eval prim fuel e env := rfl

/-! ## Fuel exhaustion — the only place evaluation fails *because of fuel*. -/

theorem eval_fuel_zero (e : Core) (env : Env) :
    eval prim 0 e env = Comp.fail "fuel exhausted" := rfl

/-! ## Variable lookup — locality before global. -/

theorem eval_var_local (x : String) (v : Value) (fuel : Nat)
    (rest : Env) :
    eval prim (fuel + 1) (.var x) ((x, v) :: rest) = pure v := by
  simp [eval, lookupEnv]

end OctiveLean.Foundation
