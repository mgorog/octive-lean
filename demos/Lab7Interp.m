% Lab 7: Polynomial interpolation of f(x) = 1/(1+x^2) on [-5, 5]
% Numerical demo (no plots): each part reports max|f(t) - fit(t)|
% sampled on t = -5:0.01:5.

f = @(x) 1 ./ (1 + x .^ 2);

t = -5:0.01:5;
yt = f(t);

% =========================================================================
% Part 1 - Full-degree polynomial interpolation at uniform nodes
% =========================================================================
disp("Part 1: uniform nodes, polyfit(x, y, n) - interpolation");
ns = [3 6 11 15];
for k = 1:length(ns)
  n = ns(k);
  xn = linspace(-5, 5, n+1);
  yn = f(xn);
  c = polyfit(xn, yn, n);
  yp = polyval(c, t);
  err = max(abs(yt - yp));
  printf("  n+1 = %3d   degree n = %2d   max error = %.4f\n", n+1, n, err);
endfor

% =========================================================================
% Part 2 - Least-squares polynomial fit (k < n) at 12 uniform nodes
% =========================================================================
disp(" ");
disp("Part 2: least-squares polyfit(x, y, k) with k < 11 on 12 nodes");
xn = linspace(-5, 5, 12);
yn = f(xn);
for k = 1:9
  c = polyfit(xn, yn, k);
  yp = polyval(c, t);
  err = max(abs(yt - yp));
  printf("  degree k = %d   max error = %.4f\n", k, err);
endfor

% =========================================================================
% Part 3 - Natural cubic spline interpolation at 12 uniform nodes
% =========================================================================
disp(" ");
disp("Part 3: cubic spline at 12 uniform nodes");
xn = linspace(-5, 5, 12);
yn = f(xn);
ys = spline(xn, yn, t);
err = max(abs(yt - ys));
printf("  spline(12 nodes)   max error = %.6f\n", err);

% Also try other counts
for k = 1:length(ns)
  n = ns(k);
  xn = linspace(-5, 5, n+1);
  yn = f(xn);
  ys = spline(xn, yn, t);
  err = max(abs(yt - ys));
  printf("  spline(%2d nodes)  max error = %.6f\n", n+1, err);
endfor

% =========================================================================
% Part 4 - Chebyshev nodes for full-degree interpolation
% =========================================================================
disp(" ");
disp("Part 4: Chebyshev nodes - polyfit(x, y, n) - interpolation");
a = -5; b = 5;
for k = 1:length(ns)
  n = ns(k);
  zn = zeros(1, n+1);
  for j = 0:n
    zn(j+1) = (a+b)/2 + (a-b)/2 * cos(pi*j/n);
  endfor
  yn = f(zn);
  c = polyfit(zn, yn, n);
  yp = polyval(c, t);
  err = max(abs(yt - yp));
  printf("  n+1 = %3d   degree n = %2d   max error = %.4f\n", n+1, n, err);
endfor

% =========================================================================
% Part 5 - Spline at varied node counts (already partially shown)
% =========================================================================
disp(" ");
disp("Part 5: spline error vs node count (uniform)");
counts = [4 7 12 16 25 50];
for k = 1:length(counts)
  m = counts(k);
  xn = linspace(-5, 5, m);
  yn = f(xn);
  ys = spline(xn, yn, t);
  err = max(abs(yt - ys));
  printf("  %2d nodes  max error = %.6f\n", m, err);
endfor
