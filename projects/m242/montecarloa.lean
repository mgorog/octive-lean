import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `montecarloa.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
function mcpi = montecarloa(n) 
-- Produces a Monte Carlo estimate of pi 
-- using n (pseudo-) random points 
-- Version 2: array processing 
-- Plot the quarter circle
t = 0:pi/500:pi/2;
xc=cos(t);
yc = sin(t);
plot(xc,yc,"k")
axis([0,1,0,1])
hold 

-- Generate n random points and their squared distances from (0, 0)
rand("state",100*sum(clock)); --sets the state of rand based on current clock
points=rand(2,n);
dsq = points(1,:).^2 + points(2,:).^2;

-- Find and count the ones inside the quarter circle 
inside = find(dsq<1);
count = length(inside);

-- Estimate pi
mcpi = 4*count/n;

-- Plot the random points
plot(points(1,:), points(2,:),"g.",points(1,inside),points(2,inside),"r.")
title(["A Monte Carlo Estimate of \\pi is  ", num2str(mcpi)])
xlabel("x-axis")
ylabel("y-axis")
}
