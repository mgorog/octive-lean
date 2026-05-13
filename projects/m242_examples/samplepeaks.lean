import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `samplepeaks.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
function Points = samplepeaks(N)
-- Selects points off the Peaks function and its contour plot.
-- Allows the user to select N points off the countour
-- plot.  The points are returned in rows of Points variable
-- The Gradient and Hessian of the function are calculated.
-- (This requires symbolic toolbox)
-- Sample usage: >>CriticalPoints = samplepeaks(3);

whitebg "w"

-- Generate Data for Peaks Plot and Make full plot
[X,Y,Z]=peaks;
surfc(X,Y,Z)
title("The Peaks Function")
xlabel("x-axis")
ylabel("y-axis")
zlabel("z-axis")
set(gcf,"Position",[10, 600, 1000, 600])
view([-33,24])
msg1="PRESS ANY KEY TO SEE SEPARATE CONTOUR PLOT.";
disp(msg1)
text(-1,3,9,msg1)
shg
pause

figure
-- Surface Plot and Contour Plot
subplot(1,2,1)
surfc(X,Y,Z)
title("The Peaks Function")
xlabel("x-axis")
ylabel("y-axis")
zlabel("z-axis")
set(gcf,"Position",[10, 100, 1200, 500])

-- Contour Plot
subplot(1,2,2)
contour(X,Y,Z,50)
title("Level Curves of the Peaks Function")
xlabel("x-axis")
ylabel("y-axis")
--set(gcf,"Position",[400 50 600 500])

-- Mouse Selection of Points off Countour Plot
if nargin == 0
  N=input("Enter the number of points you you wish to sample off the contour plot\\n");
end

if N > 0
    if N == 1
        numstr= "a point.";
    else
        numstr= [num2str(N), "points."];
    end
    disp(["Position crosshairs and click with mouse to select ",numstr]) 
    [x1,y1]=ginput(N);
    Points=[x1,y1];
end


-- Symbolic Calculations of gradient and Hessian
-- x=sym("x");
-- y=sym("y");
-- f =  sym("3*(1-x)^2*exp(-(x^2)-(y+1)^2)- 10*(x/5 - x^3 - y^5)*exp(-x^2-y^2)- 1/3*exp(-(x+1)^2 - y^2)")
-- gradf=jacobian(f,[x,y])
-- Jf=jacobian(gradf,[x,y])
end

}
