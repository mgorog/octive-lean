import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `montecarlo_4d.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
function [hypervol, mcpi] = montecarlo_4d(n)
-- Monte Carlo estimate of 4D unit ball hypervolume and pi
rand("state",100*sum(clock));
points = rand(4,n);
dsq = points(1,:).^2 + points(2,:).^2 + points(3,:).^2 + points(4,:).^2;
inside = find(dsq < 1);
count = length(inside);
fraction = count / n;
hypervol = 16 * fraction;
mcpi = sqrt(32 * fraction);
end
}
