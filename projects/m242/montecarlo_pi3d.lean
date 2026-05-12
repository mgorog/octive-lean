import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `montecarlo_pi3d.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
function mcpi = montecarlo_pi3d(n)
-- Monte Carlo estimate of pi using 3D unit ball volume
rand("state",100*sum(clock));
points = rand(3,n);
dsq = points(1,:).^2 + points(2,:).^2 + points(3,:).^2;
inside = find(dsq < 1);
count = length(inside);
mcpi = 6 * count / n;
end
}
