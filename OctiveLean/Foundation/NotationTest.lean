import OctiveLean.Foundation.Notation

/-!
# Foundation.NotationTest — sanity checks for `octF! { … }`.

The macro emits constructor references in the call-site's namespace
(Lean hygiene prevents qualifying them through the macro). So the
user opens Foundation.Surface once at the file level.
-/

open OctiveLean.Foundation

-- Simple arithmetic
octF! {
  x = 5;
  y = x + 7;
  disp(y);
}

-- Recursion-free function with a return value
octF! {
  function r = square(z)
    r = z * z;
  end
  disp(square(6));
}

-- Conditional
octF! {
  n = 10;
  if n > 0
    disp(1);
  else
    disp(0);
  end
}
