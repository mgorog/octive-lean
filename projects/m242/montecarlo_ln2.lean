import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `montecarlo_ln2.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
function mcln2 = montecarlo_ln2(n)
-- Monte Carlo estimate of ln 2 using n random points
rand("state",100*sum(clock));
points = rand(2,n);
x = 1 + points(1,:);  -- uniform in [1,2]
y = points(2,:);      -- uniform in [0,1]
inside = find(y < 1./x);
count = length(inside);
mcln2 = count / n;
end
}
