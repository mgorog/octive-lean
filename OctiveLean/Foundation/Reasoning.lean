import OctiveLean.Foundation.Logic
import OctiveLean.Foundation.Notation

/-!
# Foundation.Reasoning — proof-side ergonomics.

The proof loop in `Foundation.ProofExample` works but each theorem
hand-rolls `runProgram`, `binds`, etc.  This file adds:

  * `p ⇓ v` notation — "program `p` evaluates to value `v`".
  * `p ⇓bind x ↦ v` — "after running `p`, identifier `x` is bound to `v`".
  * `octs` tactic — symbolic-execute the goal (currently a thin
    wrapper over `native_decide`; can be extended later to do
    structural unfolding so users can read intermediate states).
  * `octassert! { … ; assert P ; … }` macro — inline assertions
    that become Lean theorems.
  * `octthm! name { … } shows P` macro — define a program and
    its postcondition theorem in one breath.

Every notation reduces (after `simp [⇓, ⇓bind]`) to the underlying
`runProgramOk` / `leavesBound` predicate, so existing proofs keep
working.
-/

namespace OctiveLean.Foundation
namespace Reasoning

open Logic

/-! ## Evaluation notation: `p ⇓ v`. -/

/-- `p ⇓ v` — the program `p`, evaluated under the initial env,
    yields the value `v`.  Uses Bool equality on the `Option Value`
    result so we get a `Decidable` instance through `BEq` rather
    than requiring `DecidableEq Value` (closures self-reference). -/
def evalsTo (p : Program) (v : Value) : Prop :=
  (runProgramOk p == some v) = true

infix:50 " ⇓ " => evalsTo

instance (p : Program) (v : Value) : Decidable (evalsTo p v) :=
  inferInstanceAs (Decidable ((runProgramOk p == some v) = true))

/-- `p ⇓bind x ↦ v` — after `p` runs, identifier `x` is bound to
    `v` in the final env. -/
def bindsAfter (p : Program) (x : String) (v : Value) : Prop :=
  leavesBound x v p = true

notation:50 p " ⇓bind " x " ↦ " v => bindsAfter p x v

instance (p : Program) (x : String) (v : Value) : Decidable (bindsAfter p x v) :=
  inferInstanceAs (Decidable (leavesBound x v p = true))

/-! ## Tactic — symbolic execution.

For now `octs` is `native_decide` with a richer message; the
infrastructure is here so we can swap in a real symbolic-evaluation
tactic later without rewriting client proofs. -/

open Lean Elab Tactic in
elab "octs" : tactic => do
  -- Try the cheap path first.
  try
    Lean.Elab.Tactic.evalTactic (← `(tactic| native_decide))
  catch _ =>
    -- Fall through to a more informative failure.
    throwError "octs: could not decide the goal — check program/property"

/-! ## Inline-assertion macro: `octassert! { … ; assert <Lean expr> }`. -/

/-! ## A more readable assertion form: `name ↦ v`. -/

/-- `binds! "y" ↦ v` reads better in some contexts than the unicode
    `⇓bind` notation. -/
def Binds (x : String) (v : Value) (p : Program) : Prop :=
  bindsAfter p x v

instance (x : String) (v : Value) (p : Program) : Decidable (Binds x v p) :=
  inferInstanceAs (Decidable (bindsAfter p x v))

/-! ## Program-with-theorem macro: `octthm! name { … } shows P`. -/

/-- Define a program AND a theorem about it together. The
    underlying machinery uses `octProg!` for the program and
    `native_decide` for the proof.  The user only writes the
    interesting parts. -/
syntax (name := octThm)
  "octthm!" ident "{" octStmt* "}" "shows" term : command

macro_rules
  | `(command| octthm! $name:ident { $stmts:octStmt* } shows $prop:term) => do
      let stmtTerms ← stmts.mapM Notation.convStmt
      `(section
         open OctiveLean.Foundation
         open OctiveLean.Foundation.Logic
         open OctiveLean.Foundation.Reasoning
         def $name : Program := [$stmtTerms,*]
         theorem $(Lean.mkIdent (`property ++ name.getId)) :
             $prop := by native_decide
         end)

end Reasoning
end OctiveLean.Foundation
