% Example 1: 1-D non-dim gravity
%   x'  = v
%   v' = -1/x^2,   x(0) = 1, v(0) = 0
% RK4 fixed-step.

n  = 100;
t0 = 0; tf = 1.0;
h  = (tf - t0) / n;

t  = zeros(1, n+1);
xs = zeros(1, n+1);
vs = zeros(1, n+1);
xs(1) = 1.0;
vs(1) = 0.0;

for i = 1:n
  ti = t(i); xi = xs(i); vi = vs(i);
  k1x = vi;                          k1v = -1 / xi^2;
  k2x = vi + h/2*k1v;                k2v = -1 / (xi + h/2*k1x)^2;
  k3x = vi + h/2*k2v;                k3v = -1 / (xi + h/2*k2x)^2;
  k4x = vi + h*k3v;                  k4v = -1 / (xi + h*k3x)^2;
  t(i+1)  = ti + h;
  xs(i+1) = xi + h/6 * (k1x + 2*k2x + 2*k3x + k4x);
  vs(i+1) = vi + h/6 * (k1v + 2*k2v + 2*k3v + k4v);
endfor

for i = 1:n+1
  printf("%f,%f,%f\n", t(i), xs(i), vs(i));
endfor
