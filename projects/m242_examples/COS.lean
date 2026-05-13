import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `COS.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
function [y,n]=COS(x)
-- approximates y = cos(x) using Maclaurin Series and alternating series test

xc=abs(x); -- since cosine is even
-- Reduce x to xc in [0,pi/2]
n=floor(xc/(2*pi));
xc=xc-2*n*pi;
if xc>pi/2 && xc<3*pi/2
    xc=abs(pi-xc); -- reference angle
    sign=-1;
else
    sign = 1;
    if xc >= 3*pi/2
 xc=2*pi-xc;
end
end
-- special cases
if xc<eps
 y = sign;
 end
if pi/2 - xc < eps
 y = 0;
 end
-- Initialize loop quantities
y=1;
term=1;
factor = -xc^2;
n=0;
while abs(term)>eps/2
    n=n+2;
    term=term*factor/(n*(n-1));
    y = y+term;
end
y = sign*y;
end

}
