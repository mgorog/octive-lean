import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `montecarlo.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
function mcpi = montecarlo(n)
-- Produces a Monte Carlo estimate of pi
-- using n (pseudo-) random points
-- Version 1: sequential (loop) processing

-- Plot the quarter circle
t = 0:pi/500:pi/2;
xc=cos(t);
yc = sin(t);
plot(xc,yc,"k")
axis([0,1,0,1])
axis square
hold
hp=gcf;
figure(hp);
-- Generate n random points and their squared distances from (0, 0)
rand("state",100*sum(clock)); --sets the state of rand based on current clock

count=0;
for k=1:n
    
    point=rand(2,1);
    dsq = point(1,1)^2 + point(2,1)^2;
    if dsq<1
        count = count + 1;
        mcpi = 4*count/k;

        -- Plot the inside random point
        plot(point(1,1), point(2,1),"k.")
    else
        -- Plot the outside random point
        plot(point(1,1), point(2,1),"r.")
        -- Find and count the ones inside the quarter circle
    end
    title(["A Monte Carlo Estimate of \\pi is  ", num2str(mcpi)])
    pause(0.1)
end

-- Estimate pi
mcpi = 4*count/n;

-- Lable plot of random points
title(["A Monte Carlo Estimate of \\pi is  ", num2str(mcpi)])
xlabel("x-axis")
ylabel("y-axis")
hold off
}
