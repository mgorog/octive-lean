import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `randwalk.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
function [x,y]=randwalk(s) 
-- Computes and plots (using comet function)
-- a random walk of s steps from (0,0) 
--Problem4-9 Solution (Written as a function instead)

x=zeros(1,s+1); -- grab enought static memory
y=x;
plot(x(1),y(1),"bp")
hold on
rand("state",sum(100*clock)) 
for i=1:s;
    r=rand;
    if r<0.25;
        x(i+1)=x(i)+1; 
        y(i+1)=y(i);
    elseif r<0.5;
        x(i+1)=x(i)-1;
        y(i+1)=y(i);
    elseif r<0.75;
        x(i+1)=x(i);
        y(i+1)=y(i)+1;
    else
        x(i+1)=x(i);
        y(i+1)=y(i)-1;
    end
end

comet(x,y)
}
