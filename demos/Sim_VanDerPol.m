% Example 2: van der Pol oscillator
%   x'  = v
%   v'  = mu*(1 - x^2)*v - x,    x(0)=0, v(0)=1
% Use mu = 2 (stiffer values like 50 from the slide need adaptive step).

mu = 2.0;
n  = 3000;
t0 = 0; tf = 30.0;
h  = (tf - t0) / n;

t  = zeros(1, n+1);
xs = zeros(1, n+1);
vs = zeros(1, n+1);
xs(1) = 0.0;
vs(1) = 1.0;

for i = 1:n
  ti = t(i); xi = xs(i); vi = vs(i);
  k1x = vi;                                k1v = mu*(1 - xi^2)*vi - xi;
  ax  = xi + h/2*k1x; av  = vi + h/2*k1v;
  k2x = av;                                k2v = mu*(1 - ax^2)*av - ax;
  ax  = xi + h/2*k2x; av  = vi + h/2*k2v;
  k3x = av;                                k3v = mu*(1 - ax^2)*av - ax;
  ax  = xi + h*k3x;   av  = vi + h*k3v;
  k4x = av;                                k4v = mu*(1 - ax^2)*av - ax;
  t(i+1)  = ti + h;
  xs(i+1) = xi + h/6 * (k1x + 2*k2x + 2*k3x + k4x);
  vs(i+1) = vi + h/6 * (k1v + 2*k2v + 2*k3v + k4v);
endfor

% Print every 10th sample to keep CSV manageable
for i = 1:10:n+1
  printf("%f,%f,%f\n", t(i), xs(i), vs(i));
endfor
