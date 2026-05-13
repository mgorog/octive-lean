import OctiveLean.Foundation.Reasoning

/-!
# Foundation.ProofExample2 — the ergonomic proof loop.

Same exercises as `ProofExample.lean`, written with the new
`octthm!` / `⇓` / `⇓bind` / `octs` vocabulary. Compare side-by-side:
the before required hand-rolling `runProgramOk`, `leavesBound`,
`native_decide`; the after says what it means and lets the
infrastructure carry it.
-/

namespace OctiveLean.Foundation.ProofExample2

open OctiveLean.Foundation
open OctiveLean.Foundation.Logic
open OctiveLean.Foundation.Reasoning

/-! ## Program-with-theorem in one breath. -/

octthm! addAndShow {
  x = 5;
  y = x + 7;
} shows addAndShow ⇓ Value.num 12.0

octthm! squareSix {
  function r = square(z)
    r = z * z;
  end
  ans = square(6);
} shows squareSix ⇓bind "ans" ↦ Value.num 36.0

octthm! branchPos {
  n = 10;
  if n > 0
    s = "pos";
  else
    s = "neg";
  end
} shows branchPos ⇓bind "s" ↦ Value.str "pos"

/-! ## Or, hand-rolled with `octs`. -/

octProg! reuseExample {
  a = 3;
  b = 4;
  c = a * a + b * b;  -- Pythagorean — 25
}

theorem reuseExample_c_eq_25 : reuseExample ⇓bind "c" ↦ Value.num 25.0 := by octs

/-! ## Compose: derive properties from running. -/

theorem reuseExample_returns_25 : reuseExample ⇓ Value.num 25.0 := by octs

end OctiveLean.Foundation.ProofExample2
