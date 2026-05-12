import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `fact_custom.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {

function f = fact_custom(n)
  -- computes n! recursivly
  if n>0
      f = n*fact_custom(n-1)
  else
      f = 1
  end
end
}
