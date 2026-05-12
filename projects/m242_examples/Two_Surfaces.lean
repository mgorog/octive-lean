import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `Two_Surfaces.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
-- Plot Multiple Surfaces on One Set of Axes
-- B. Lundberg, March 29, 2018
 [Xc,Yc,Zc] = cylinder(10); 
 surf(Xc, Yc, Zc)
 hold on
 surf(Zc, Xc, Yc)
 
x=-10:1:10;y = x; [X, Y] = meshgrid(x,y);Z = 2*X - 3*Y; -- Making data for a plane surface

surf(X,Y,Z)
xlabel("x-axis"),ylabel("y-axis"),zlabel("z-axis")

[Xs,Ys,Zs] = sphere(10);
scale=5;
surf(scale*Xs,scale*Ys,scale*Zs)

-- You can change the surface colors manually (mousing on the toolbar menue)
-- or automatically by setting options for each plot.
}
