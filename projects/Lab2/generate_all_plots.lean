import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `generate_all_plots.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
-- generate_all_plots.m (COMPACT, REPEATED-CODE VERSION - Should work without syntax errors)
-- This generates the 4 original PNG files used in your early LaTeX versions:
-- - plot_workspace.png : Uses the corrected Example 2 (solution 7, -2)
-- - plot_prompt.png    : Uses Example 1 (solution 2, 2)
-- - plot_func.png      : Uses Example 1 (solution 2, 2)
-- - plot_curves.png    : Task 2 with nice superscripts in legend
-- It prints solutions for verification.

close all;

-- =============== Plot for Task 1a (workspace) - Example 2 corrected ===============
A = [2, 3; 4, 5];
b = [8; 18];

sol = linsolve(A, b;

fprintf("\\nTask 1a workspace - Example 2\\n");
disp("A ="); disp(A);
disp("b ="); disp(b);
disp("Solution:"); disp(sol);

figure("visible","off");
hold on; grid on;
xlabel("x"); ylabel("y");
title("Lines and Intersection");

x_sol = sol(1);
y_sol = sol(2);

padding = max(abs([x_sol, y_sol])) + 5;
if padding < 10
  padding = 10;
end

x_min = x_sol - padding;
x_max = x_sol + padding;

-- Line 1
if abs(A(1,2)) > 1e-10
  x_vals = linspace(x_min, x_max, 200);
  y_vals = (b(1) - A(1,1)*x_vals) / A(1,2);
  plot(x_vals, y_vals, "b-", "LineWidth", 2);
else
  x_val = b(1)/A(1,1);
  y_vals = linspace(y_sol-padding, y_sol+padding, 200);
  plot(x_val*ones(size(y_vals)), y_vals, "b-", "LineWidth", 2);
end

-- Line 2
if abs(A(2,2)) > 1e-10
  x_vals = linspace(x_min, x_max, 200);
  y_vals = (b(2) - A(2,1)*x_vals) / A(2,2);
  plot(x_vals, y_vals, "r--", "LineWidth", 2);
else
  x_val = b(2)/A(2,1);
  y_vals = linspace(y_sol-padding, y_sol+padding, 200);
  plot(x_val*ones(size(y_vals)), y_vals, "r--", "LineWidth", 2);
end

text(x_sol + 0.05*padding, y_sol + 0.05*padding,  sprintf("(%g, %g)", x_sol, y_sol));

hold off;
print("-dpng", "plot_workspace.png");
fprintf("Saved: plot_workspace.png\\n");

-- =============== Plot for Task 1b (prompt) - Example 1 ===============
A = [1, 1; 1, -1];
b = [4; 0];

sol = linsolve(A, b;

fprintf("\\nTask 1b prompt - Example 1\\n");
disp("Solution:"); disp(sol);

figure("visible","off");
hold on; grid on;
xlabel("x"); ylabel("y");
title("Lines and Intersection");

x_sol = sol(1);
y_sol = sol(2);

padding = max(abs([x_sol, y_sol])) + 5;
if padding < 10
  padding = 10;
end

x_min = x_sol - padding;
x_max = x_sol + padding;

-- Line 1
if abs(A(1,2)) > 1e-10
  x_vals = linspace(x_min, x_max, 200);
  y_vals = (b(1) - A(1,1)*x_vals) / A(1,2);
  plot(x_vals, y_vals, "b-", "LineWidth", 2);
else
  x_val = b(1)/A(1,1);
  y_vals = linspace(y_sol-padding, y_sol+padding, 200);
  plot(x_val*ones(size(y_vals)), y_vals, "b-", "LineWidth", 2);
end

-- Line 2
if abs(A(2,2)) > 1e-10
  x_vals = linspace(x_min, x_max, 200);
  y_vals = (b(2) - A(2,1)*x_vals) / A(2,2);
  plot(x_vals, y_vals, "r--", "LineWidth", 2);
else
  x_val = b(2)/A(2,1);
  y_vals = linspace(y_sol-padding, y_sol+padding, 200);
  plot(x_val*ones(size(y_vals)), y_vals, "r--", "LineWidth", 2);
end

text(x_sol + 0.05*padding, y_sol + 0.05*padding,  sprintf("(%g, %g)", x_sol, y_sol));

hold off;
print("-dpng", "plot_prompt.png");
fprintf("Saved: plot_prompt.png\\n");

-- =============== Plot for Task 1c (function) - Example 1 ===============
A = [1, 1; 1, -1];
b = [4; 0];

sol = linsolve(A, b;

fprintf("\\nTask 1c function - Example 1\\n");
disp("Solution:"); disp(sol);

figure("visible","off");
hold on; grid on;
xlabel("x"); ylabel("y");
title("Lines and Intersection");

x_sol = sol(1);
y_sol = sol(2);

padding = max(abs([x_sol, y_sol])) + 5;
if padding < 10
  padding = 10;
end

x_min = x_sol - padding;
x_max = x_sol + padding;

-- Line 1 & Line 2 (same as above)
if abs(A(1,2)) > 1e-10
  x_vals = linspace(x_min, x_max, 200);
  y_vals = (b(1) - A(1,1)*x_vals) / A(1,2);
  plot(x_vals, y_vals, "b-", "LineWidth", 2);
else
  x_val = b(1)/A(1,1);
  y_vals = linspace(y_sol-padding, y_sol+padding, 200);
  plot(x_val*ones(size(y_vals)), y_vals, "b-", "LineWidth", 2);
end

if abs(A(2,2)) > 1e-10
  x_vals = linspace(x_min, x_max, 200);
  y_vals = (b(2) - A(2,1)*x_vals) / A(2,2);
  plot(x_vals, y_vals, "r--", "LineWidth", 2);
else
  x_val = b(2)/A(2,1);
  y_vals = linspace(y_sol-padding, y_sol+padding, 200);
  plot(x_val*ones(size(y_vals)), y_vals, "r--", "LineWidth", 2);
end

text(x_sol + 0.05*padding, y_sol + 0.05*padding,  sprintf("(%g, %g)", x_sol, y_sol));

hold off;
print("-dpng", "plot_func.png");
fprintf("Saved: plot_func.png\\n");

-- =============== Task 2 curves ===============
w = 1;
n = 100;

period = 2*pi / w;
x_range = 4 * period;
x = linspace(-x_range/2, x_range/2, n);

y1 = sin(w * x);
y2 = w*x - (w*x).^3 / 6;
y3 = w*x - (w*x).^3 / 6 + (w*x).^5 / 120;

figure("visible","off");
hold on; grid on;
xlabel("x"); ylabel("y");
title("Sine and Taylor Approximations");

plot(x, y1, "b-", "LineWidth", 2);
plot(x, y1, "b*");
plot(x, y2, "r--", "LineWidth", 2);
plot(x, y3, "g:", "LineWidth", 2);

legend("y = sin(w x)",  "y = w x - (w x)^3/6",  "y = w x - (w x)^3/6 + (w x)^5/120",  "Interpreter", "tex",  "Location", "best");

hold off;
print("-dpng", "plot_curves.png");
fprintf("Saved: plot_curves.png\\n");
}
