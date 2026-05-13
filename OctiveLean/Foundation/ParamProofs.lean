import OctiveLean.Foundation.Reasoning

/-!
# Foundation.ParamProofs — parametric theorems over the Core semantics.

`Compile.compile` is `partial def` (mutual-block termination open),
so theorems about *Surface* programs need `native_decide` on
concrete inputs. At the **Core level** (`eval`) everything is
total, so we can quantify over inputs and prove by `rfl` where the
operational semantics commutes with the constructor at hand.

Each theorem here holds for **every input of its shape** — a small
library that compounds into bigger proofs once we add inversion
lemmas + a step tactic.
-/

namespace OctiveLean.Foundation.ParamProofs

open OctiveLean.Foundation
open OctiveLean.Foundation.Eval

/-! ## Literal evaluation — closed by `rfl` for any payload. -/

theorem eval_lit_num (prim : PrimopDispatch) (fuel : Nat) (env : Env) (n : Float) :
    eval prim (fuel + 1) (.lit (.float n)) env = pure (.num n) := rfl

theorem eval_lit_str (prim : PrimopDispatch) (fuel : Nat) (env : Env) (s : String) :
    eval prim (fuel + 1) (.lit (.str s)) env = pure (.str s) := rfl

theorem eval_lit_bool (prim : PrimopDispatch) (fuel : Nat) (env : Env) (b : Bool) :
    eval prim (fuel + 1) (.lit (.bool b)) env = pure (.bool b) := rfl

/-! ## Lambda — captures the env exactly. -/

theorem eval_lam (prim : PrimopDispatch) (fuel : Nat) (env : Env)
    (ps : List String) (body : Core) :
    eval prim (fuel + 1) (.lam ps body) env =
      pure (.closure ps body env) := rfl

/-! ## Sequence — second expression's value is the result. -/

theorem eval_seq (prim : PrimopDispatch) (fuel : Nat) (env : Env) (a b : Core) :
    eval prim (fuel + 1) (.seq a b) env =
      (do let _ ← eval prim fuel a env; eval prim fuel b env) := rfl

/-! ## Let — extends the env before evaluating the body. -/

theorem eval_letin (prim : PrimopDispatch) (fuel : Nat) (env : Env)
    (x : String) (e₁ e₂ : Core) :
    eval prim (fuel + 1) (.letin x e₁ e₂) env =
      (do let v ← eval prim fuel e₁ env
          eval prim fuel e₂ ((x, v) :: env)) := rfl

/-! ## Conditional — strict on condition, branches by `truthy`. -/

theorem eval_ifte (prim : PrimopDispatch) (fuel : Nat) (env : Env) (c t e : Core) :
    eval prim (fuel + 1) (.ifte c t e) env =
      (do let cv ← eval prim fuel c env
          if truthy cv then eval prim fuel t env else eval prim fuel e env) := rfl

/-! ## Composed theorem: a literal-let returns the literal. -/

/-- For any literal `n`, `letin x (lit n) (var x)` returns `n`.
    A composition of `eval_letin`, `eval_lit_num`, and the
    head-lookup step. -/
theorem letin_lit_returns
    (prim : PrimopDispatch) (fuel : Nat) (env : Env) (x : String) (n : Float) :
    eval prim (fuel + 1 + 1) (.letin x (.lit (.float n)) (.var x)) env =
      pure (.num n) := by
  rw [eval_letin]
  simp [eval_lit_num, pure, ExceptT.pure]
  unfold eval
  simp [lookupEnv]

/-! ## Family example: a parameterised Core program. -/

/-- The Core term `let x = n in x`. -/
def assignAndReturn (n : Float) : Core :=
  .letin "x" (.lit (.float n)) (.var "x")

/-- For every `n`, the Core program returns `.num n`. -/
theorem assignAndReturn_returns (prim : PrimopDispatch) (env : Env) (n : Float) :
    eval prim 3 (assignAndReturn n) env = pure (.num n) := by
  exact letin_lit_returns prim 1 env "x" n

end OctiveLean.Foundation.ParamProofs
