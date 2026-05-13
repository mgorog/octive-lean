import OctiveLean.Foundation.Notation
import OctiveLean.Foundation.Logic

/-!
# Foundation.ProofExample — write Octave, prove it.

A demonstration of the proof loop:

  1. `octProg! name { … }` defines an Octave program as a Lean
     value `name : Surface.Program`.
  2. Theorems are stated about `name` using the predicates from
     `Foundation.Logic` — `runProgramOk`, `leavesBound`, `HoareTriple`.
  3. Proofs are by computation (`rfl` / `decide`) for closed
     programs and by induction for parameterised ones.

The point: you write the Octave source once, then any number of
theorems about its behaviour can hang off the same `def`.
-/

namespace OctiveLean.Foundation.ProofExample

open OctiveLean.Foundation
open OctiveLean.Foundation.Logic

-- shadow the imperative-path `OctiveLean.runProgram` so theorems
-- below pick up `Logic.runProgram`.
private abbrev runProgram := Logic.runProgram

/-! ## Example 1: `x = 5; y = x + 7` leaves `y = 12`. -/

octProg! addExample {
  x = 5;
  y = x + 7;
}

/-- The final value of the program is the value of the last
    statement; for an assignment `y = x + 7;` that's `12.0`. -/
theorem addExample_returns_12 :
    runProgramOk addExample == some (.num 12.0) := by
  native_decide

/-- After the program runs, `y` is bound to `12.0` in the env. -/
theorem addExample_y_eq_12 : leavesBound "y" (.num 12.0) addExample = true := by
  native_decide

/-- And `x` keeps the value `5.0`. -/
theorem addExample_x_eq_5 : leavesBound "x" (.num 5.0) addExample = true := by
  native_decide

/-! ## Example 2: a Hoare triple — from any state, the program
    leaves `y` bound to 12. -/

/-- The concrete instance of the triple at the initial state. The
    fully-parametric `HoareTriple (fun _ => True)` form requires a
    `runProgram_env_invariance` lemma (saying the program's effect
    on `env` doesn't depend on the rest of the initial state) which
    is a lemma about `Compile.compile` we have not yet derived. -/
theorem addExample_postcondition_initial :
    let (s', _) := runProgram addExample { env := Initial.env }
    binds "y" (.num 12.0) s'.env = true := by
  native_decide

/-! ## Example 3: a small function — `square(6) = 36`. -/

octProg! squareExample {
  function r = square(z)
    r = z * z;
  end
  ans = square(6);
}

theorem squareExample_ans_eq_36 :
    leavesBound "ans" (.num 36.0) squareExample = true := by
  native_decide

/-! ## Example 4: branching — `n = 10; if n > 0 then s = "pos"`. -/

octProg! branchExample {
  n = 10;
  if n > 0
    s = "pos";
  else
    s = "neg";
  end
}

theorem branchExample_s_pos : leavesBound "s" (.str "pos") branchExample = true := by
  native_decide

end OctiveLean.Foundation.ProofExample
