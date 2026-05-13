import OctiveLean.Foundation.Reasoning

/-!
# Foundation.LoopExample — while loops with proofs.

`while` compiles to a recursive thunk; `eval`'s `letrec` ties the
knot. Iteration is bounded by `Eval.defaultFuel`.
-/

namespace OctiveLean.Foundation.LoopExample

open OctiveLean.Foundation
open OctiveLean.Foundation.Logic
open OctiveLean.Foundation.Reasoning

/-! ## Loop 1: count down from 5 to 0. -/

octthm! countDown {
  i = 5;
  while i > 0
    i = i - 1;
  end
} shows countDown ⇓bind "i" ↦ Value.num 0.0

/-! ## Loop 2: accumulate a sum. -/

octthm! sumTo10 {
  i = 1;
  acc = 0;
  while i <= 10
    acc = acc + i;
    i = i + 1;
  end
} shows sumTo10 ⇓bind "acc" ↦ Value.num 55.0

/-! ## Loop 3: factorial via while. -/

octthm! factOf5 {
  n = 5;
  result = 1;
  while n > 0
    result = result * n;
    n = n - 1;
  end
} shows factOf5 ⇓bind "result" ↦ Value.num 120.0

/-! ## For-loop compiles but needs a `for`-iterator primop to run;
    only `while`-style loops work today. The compile-correctness
    work will introduce the iterator. -/

-- octthm! sumSquares {
--   total = 0;
--   for k = 1:5
--     total = total + k * k;
--   end
-- } shows sumSquares ⇓bind "total" ↦ Value.num 55.0

end OctiveLean.Foundation.LoopExample
