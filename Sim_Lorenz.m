% Example 3: Lorenz system
%   x' = -sigma*x + sigma*y
%   y' =  rho*x - y - x*z
%   z' = -beta*z + x*y
% Slide uses sigma = 10, rho = 70, beta = 8/3, x0=y0=z0=1.

sigma = 10.0;
rho   = 70.0;
beta  = 8.0/3.0;

n  = 5000;
t0 = 0; tf = 25.0;
h  = (tf - t0) / n;

t  = zeros(1, n+1);
xs = zeros(1, n+1);
ys = zeros(1, n+1);
zs = zeros(1, n+1);
xs(1) = 1.0;
ys(1) = 1.0;
zs(1) = 1.0;

for i = 1:n
  ti = t(i); xi = xs(i); yi = ys(i); zi = zs(i);
  k1x = -sigma*xi + sigma*yi;
  k1y = rho*xi - yi - xi*zi;
  k1z = -beta*zi + xi*yi;

  ax = xi + h/2*k1x; ay = yi + h/2*k1y; az = zi + h/2*k1z;
  k2x = -sigma*ax + sigma*ay;
  k2y = rho*ax - ay - ax*az;
  k2z = -beta*az + ax*ay;

  ax = xi + h/2*k2x; ay = yi + h/2*k2y; az = zi + h/2*k2z;
  k3x = -sigma*ax + sigma*ay;
  k3y = rho*ax - ay - ax*az;
  k3z = -beta*az + ax*ay;

  ax = xi + h*k3x; ay = yi + h*k3y; az = zi + h*k3z;
  k4x = -sigma*ax + sigma*ay;
  k4y = rho*ax - ay - ax*az;
  k4z = -beta*az + ax*ay;

  t(i+1)  = ti + h;
  xs(i+1) = xi + h/6 * (k1x + 2*k2x + 2*k3x + k4x);
  ys(i+1) = yi + h/6 * (k1y + 2*k2y + 2*k3y + k4y);
  zs(i+1) = zi + h/6 * (k1z + 2*k2z + 2*k3z + k4z);
endfor

% Print every 10th sample
for i = 1:10:n+1
  printf("%f,%f,%f,%f\n", t(i), xs(i), ys(i), zs(i));
endfor
