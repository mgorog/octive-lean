import OctiveLean.Foundation.Identity

/-!
# Foundation.IdentityExample — equivalence reasoning in action.

The identities in `Foundation.Identity` let us reason about
program transformations without re-running them. This file shows:

  1. Hand-written equivalences (Octave + Octave, prove ≡).
  2. Equivalence-by-composition: chain identities.
  3. Equivalence on multi-statement programs.
-/

namespace OctiveLean.Foundation.IdentityExample

open OctiveLean.Foundation
open OctiveLean.Foundation.Reasoning
open OctiveLean.Foundation.Identity

/-! ## Direct equivalence: two programs, same observable result. -/

octProg! original  { x = 0 + 42; }
octProg! optimised { x = 42;    }

theorem opt_preserves_meaning : original ≡p optimised := by native_decide

/-! ## A redundant computation is equivalent to a direct one. -/

octProg! redundant { x = 1 * (0 + 7); }
octProg! direct    { x = 7;            }

theorem redundant_to_direct : redundant ≡p direct := by native_decide

/-! ## Last-write-wins eliminates dead writes. -/

octProg! deadWrite {
  x = 99;
  x = 1;
}
octProg! liveWrite {
  x = 1;
}

theorem dead_eliminated : deadWrite ≡p liveWrite := by native_decide

/-! ## Constant-folded conditional. -/

octProg! branchByConst {
  if true
    r = 1;
  else
    r = 2;
  end
}
octProg! straightLine {
  r = 1;
}

theorem branch_folded : branchByConst ≡p straightLine := by native_decide

end OctiveLean.Foundation.IdentityExample
