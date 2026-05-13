import OctiveLean.Foundation.Reasoning

/-!
# Foundation.Identity — algebraic identities over Octave programs.

The point: program transformations don't have to be re-run to be
trusted. Each identity here is a theorem; a future rewrite tactic
can use them as rewrites and the result is provably equivalent to
the original.

Two relations:

  * `p ⇓ v` (from `Foundation.Reasoning`) — "p evaluates to v".
  * `p₁ ≡p p₂` — "p₁ and p₂ produce equal final-value results
    under the initial state".

Identities hold over `Initial.env`-starting runs.  Generalising to
arbitrary initial states is the `runProgram_env_invariance` lemma
on the longer roadmap.
-/

namespace OctiveLean.Foundation
namespace Identity

open Logic Reasoning

/-- Two programs are observationally equivalent on the initial
    state when their final values agree. -/
def Equiv (p₁ p₂ : Program) : Prop :=
  (runProgramOk p₁ == runProgramOk p₂) = true

infix:50 " ≡p " => Equiv

instance (p₁ p₂ : Program) : Decidable (Equiv p₁ p₂) :=
  inferInstanceAs (Decidable ((runProgramOk p₁ == runProgramOk p₂) = true))

/-! ## A handful of identities — each is one `decide` / `native_decide` away. -/

/-- `x = 0 + 42;` ≡ `x = 42;`. -/
theorem add_zero_left :
    ([.assign (.id "x") (.binop .add (.num 0.0) (.num 42.0)) .silent] : Program) ≡p
    [.assign (.id "x") (.num 42.0) .silent] := by native_decide

/-- `x = 42 + 0;` ≡ `x = 42;`. -/
theorem add_zero_right :
    ([.assign (.id "x") (.binop .add (.num 42.0) (.num 0.0)) .silent] : Program) ≡p
    [.assign (.id "x") (.num 42.0) .silent] := by native_decide

/-- `x = 1 * 7;` ≡ `x = 7;`. -/
theorem mul_one_left :
    ([.assign (.id "x") (.binop .mul (.num 1.0) (.num 7.0)) .silent] : Program) ≡p
    [.assign (.id "x") (.num 7.0) .silent] := by native_decide

/-- `if true then a else b` ≡ `a`. -/
theorem if_true_simplifies :
    ([ .ifS (.bool true)
            [.assign (.id "r") (.num 1.0) .silent]
            []
            (some [.assign (.id "r") (.num 2.0) .silent]) ] : Program) ≡p
    [.assign (.id "r") (.num 1.0) .silent] := by native_decide

/-- `if false then a else b` ≡ `b`. -/
theorem if_false_simplifies :
    ([ .ifS (.bool false)
            [.assign (.id "r") (.num 1.0) .silent]
            []
            (some [.assign (.id "r") (.num 2.0) .silent]) ] : Program) ≡p
    [.assign (.id "r") (.num 2.0) .silent] := by native_decide

/-- Last write wins: `x = 1; x = 2;` ≡ `x = 2;`. -/
theorem last_write_wins :
    ([ .assign (.id "x") (.num 1.0) .silent
     , .assign (.id "x") (.num 2.0) .silent ] : Program) ≡p
    [.assign (.id "x") (.num 2.0) .silent] := by native_decide

end Identity
end OctiveLean.Foundation
