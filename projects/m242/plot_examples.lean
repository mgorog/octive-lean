import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `plot_examples.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
-- Complete MATLAB/Octave script with original resolution (100 points).
-- No graphics toolkit changes; using default (likely gnuplot in Octave, which may be slower for 3D plots).
-- There are no explicit loops or iterations in the user code that could run forever—all operations are vectorized and finite.
-- The meshgrid creates a 100x100 grid (10,000 points), with element-wise computations; no iteration cutoff needed as it completes quickly on most systems.
-- If plotting is slow in Octave, consider installing FLTK or Qt toolkit manually, or reduce "100" in linspace to a smaller number (e.g., 30) for testing.

close all;
clear all;

--% Section 1: Surface and Contour Plots of z = y^x - x^y
y = linspace(0.1, 6, 100);
x = linspace(0.1, 6, 100);
[X, Y] = meshgrid(x, y);
Z = Y.^X - X.^Y;
surfc(X, Y, Z)
xlabel("x-axis")
ylabel("y-axis")
zlabel("z-axis")
title("The Surface z = y^x - x^y")
saveas(gcf, "surface_plot.png")

figure
contour(X, Y, Z, -10:1:0)
xlabel("x-axis")
ylabel("y-axis")
title("Contours of y^x - x^y")
saveas(gcf, "contour_plot.png")

--% Section 2: Sample Handle Graphics Commands
figure
t = 0:pi/50:8*pi;
x = cos(t);
y = 2*sin(3*t);
z = t;
subplot(2, 2, 1)
hp = plot(x, y, "r");
ht = title("Example 1");
hy = ylabel("y-axis");
set(ht, "FontSize", 14)
set(hp, "LineStyle", "-.", "LineWidth", 2)
set(ht, "Rotation", 10)
-- set(hy)  % Commented out; displays object properties in interactive session

-- 3-D Line Plot
y = 2*sin(t);  -- Redefine y for this plot
subplot(2, 2, 2)
plot3(x, y, z)
xlabel("x-axis")
ylabel("y-axis")
zlabel("z-axis")
grid on
title("Helix")

-- Surface Plot
x = linspace(-3, 3, 100);
y = linspace(-5, 4, 100);
[X, Y] = meshgrid(x, y);
Z = X.^2 - Y.^2;
subplot(2, 2, 3)
surfc(X, Y, Z)
title("Surface Plot with Level Curves")

subplot(2, 2, 4)
contour(X, Y, Z)
title("Contour Plot")
saveas(gcf, "sample_handles.png")

--% Section 3: Multiple Axes - Resetting Axes Ticks and Labels
figure
sales = [5, 10, 12, 17];
hp = plot(sales);
set(hp, "LineWidth", 2.0)
hold_on()
hpp = plot(sales, "rp");
set(hpp, "MarkerSize", 14)

v1 = axis;
v1(3:4) = [0, 20];
axis(v1)

ax1 = gca;
set(ax1, "XTick", 1:4)
set(ax1, "XTickLabel", {"Jan"; "Feb"; "Mar"; "Apr"})
ytk = get(ax1, "YTick");
ytkl = get(ax1, "YTickLabel");
set(ax1, "YTick", ytk(1:numel(ytk)-1))
set(ax1, "YTickLabel", ytkl(1:numel(ytkl)-1, :))
ht = title("Monthly Sales 2010");
tv = get(ht, "Position");
set(ht, "Position", tv + [0, -0.4, 0], "FontWeight", "bold", "FontSize", 18, "Color", "red")

hy_us = ylabel("$ US");
set(hy_us, "Position", get(hy_us, "Position") + [-1.0, 0, 0])
set(hy_us, "Rotation", 0)
xlabel("US English")
grid(ax1)

ax2 = axes("Position", get(ax1, "Position"), "XAxisLocation", "top",  "YAxisLocation", "right", "Color", "none", "XColor", "b", "YColor", "b");
axis(ax2, axis(ax1))
set(ax2, "XTick", 1:4)
set(ax2, "XTickLabel", {"Tami"; "Hel"; "Maa"; "Huh"}, "FontAngle", "oblique")
xlabel("Finnish")

D2Euro = 1/1.3732;
y2vals = D2Euro * str2num(get(ax1, "YTickLabel"));
y2lab = num2str(y2vals);
y2lab = y2lab(:, 1:5);  -- Truncate to make labels same length
set(ax2, "YTickLabel", y2lab, "YDir", "normal")
ylabel("Euro (\\epsilon )")
-- grid(ax2)  % Not needed unless tick positions differ
saveas(gcf, "multiple_axes.png")

disp("All plots generated and saved successfully.");
}
