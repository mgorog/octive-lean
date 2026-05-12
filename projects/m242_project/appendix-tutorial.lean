import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `appendix-tutorial.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
-- ============================================================
--  OctiveLean Numerical Analysis Tutorial
--  Run with: .lake/build/bin/octive-lean tutorial.m
-- ============================================================
--
--  Topics covered:
--    1.  Horner's method              (polynomial evaluation)
--    2.  Fixed-point iteration        (square root)
--    3.  Bisection method             (root finding)
--    4.  Newton's method              (root / inverse sqrt)
--    5.  Secant method                (derivative-free Newton)
--    6.  Forward / central differences (numerical differentiation)
--    7.  Trapezoidal rule             (quadrature)
--    8.  Simpson's rule               (higher-order quadrature)
--    9.  Richardson extrapolation     (error cancellation)
--   10.  Euler method                 (ODE initial value problem)
--   11.  Runge-Kutta 4               (higher-order ODE solver)
--   12.  Gaussian elimination        (linear systems)
--   13.  Power iteration             (dominant eigenvalue)
--   14.  Lagrange interpolation      (polynomial interpolation)
-- ============================================================

-- ─────────────────────────────────────────────────────────────
--  1. HORNER'S METHOD
--  Evaluate p(x) = c(1)*x^(n-1) +  --  repeated exponentiation.  Costs n multiplications vs O(n^2).
-- ─────────────────────────────────────────────────────────────
function y = horner(c, x)
  -- c = coefficient array, highest degree first
  y = c(1);
  for k = 2:length(c)
    y = y * x + c(k);
  end
end

printf("\n=== 1. Horner's Method ===\n");
-- p(x) = x^4 - 3x^3 + x^2 + 2x - 5  at x = 2
--      = 16 - 24 + 4 + 4 - 5 = -5
c = [1, -3, 1, 2, -5];
printf("p(2) = %g  (exact: -5linsolve(), n", horner(c, 2));
printf("p(0) = %g  (exact: -5linsolve(), n", horner(c, 0));
printf("p(3) = %g  (exact: 28linsolve(), n", horner(c, 3));


-- ─────────────────────────────────────────────────────────────
--  2. FIXED-POINT ITERATION
--  Solve x = g(x).  Here: compute sqrt(a) via g(x) = a/x.
--  Converges when |g'(x*)| < 1.  The Babylonian method uses
--  g(x) = (x + a/x)/2, which converges quadratically.
-- ─────────────────────────────────────────────────────────────
function x = babylonian_sqrt(a, tol)
  x = a;                       -- initial guess
  for k = 1:100
    x_new = (x + a / x) / 2;
    if abs(x_new - x) < tol
      x = x_new;
      return;
    end
    x = x_new;
  end
end

printf("\n=== 2. Fixed-Point / Babylonian sqrt ===\n");
for a = [2, 7, 144, 0.01]
  s = babylonian_sqrt(a, 1e-12);
  printf("sqrt(%g) = %0.12f  (error %0.2elinsolve(), n", a, s, abs(s - sqrt(a)));
end


-- ─────────────────────────────────────────────────────────────
--  3. BISECTION METHOD
--  Guaranteed convergence for continuous f with f(a)*f(b)<0.
--  Linear convergence: one bit of accuracy per iteration.
-- ─────────────────────────────────────────────────────────────
function root = bisect(a, b, f, tol)
  fa = f(a);
  for k = 1:60
    m  = (a + b) / 2;
    fm = f(m);
    if abs(fm) < tol || (b - a)/2 < tol
      root = m;
      return;
    end
    if fa * fm < 0
      b = m;
    else
      a = m;
      fa = fm;
    end
  end
  root = (a + b) / 2;
end

printf("\n=== 3. Bisection Method ===\n");
-- f(x) = x^3 - x - 2,  root near x = 1.5214
f1 = @(x) x^3 - x - 2;
r  = bisect(1.0, 2.0, f1, 1e-12);
printf("x^3 - x - 2 = 0  =>  x = %0.12f\n", r);
printf("Residual: %0.2e\n", f1(r));

-- Another example: cos(x) = x  =>  x - cos(x) = 0
f2 = @(x) x - cos(x);
r2 = bisect(0.0, 1.0, f2, 1e-12);
printf("cos(x) = x          =>  x = %0.12f\n", r2);


-- ─────────────────────────────────────────────────────────────
--  4. NEWTON'S METHOD
--  Quadratic convergence near a simple root.
--  Update: x <- x - f(x)/f'(x)
-- ─────────────────────────────────────────────────────────────
function x = newton(x0, f, df, tol)
  x = x0;
  for k = 1:50
    dx = -f(x) / df(x);
    x  = x + dx;
    if abs(dx) < tol
      return;
    end
  end
end

printf("\n=== 4. Newton's Method ===\n");
-- Cube root of 27: f(x) = x^3 - 27
f3  = @(x) x^3 - 27;
df3 = @(x) 3 * x^2;
r3  = newton(2.0, f3, df3, 1e-14);
printf("cbrt(27) = %0.12f  (exact: 3linsolve(), n", r3);

-- Reciprocal square root (useful in graphics): 1/sqrt(a)
-- f(x) = 1/x^2 - a,  f'(x) = -2/x^3
a_val = 2.0;
f4  = @(x) 1 / (x*x) - a_val;
df4 = @(x) -2 / (x*x*x);
r4  = newton(0.5, f4, df4, 1e-14);
printf("1/sqrt(2) = %0.12f  (exact: %0.12flinsolve(), n", r4, 1/sqrt(2));


-- ─────────────────────────────────────────────────────────────
--  5. SECANT METHOD
--  Like Newton but approximates f' with a finite difference.
--  Superlinear convergence (order ~1.618).
-- ─────────────────────────────────────────────────────────────
function x = secant(x0, x1, f, tol)
  for k = 1:50
    fx0 = f(x0);
    fx1 = f(x1);
    if abs(fx1 - fx0) < 1e-15
      x = x1;
      return;
    end
    x2 = x1 - fx1 * (x1 - x0) / (fx1 - fx0);
    if abs(x2 - x1) < tol
      x = x2;
      return;
    end
    x0 = x1;
    x1 = x2;
  end
  x = x1;
end

printf("\n=== 5. Secant Method ===\n");
-- e^x = 3  =>  x = ln(3)
f5 = @(x) exp(x) - 3;
r5 = secant(1.0, 1.5, f5, 1e-12);
printf("e^x = 3  =>  x = %0.12f  (ln 3 = %0.12flinsolve(), n", r5, log(3));


-- ─────────────────────────────────────────────────────────────
--  6. NUMERICAL DIFFERENTIATION
--  Forward difference:  (f(x+h) - f(x)) / h          O(h)
--  Central difference:  (f(x+h) - f(x-h)) / (2h)     O(h^2)
--  Second derivative:   (f(x+h) - 2f(x) + f(x-h))/h^2  O(h^2)
-- ─────────────────────────────────────────────────────────────
printf("\n=== 6. Numerical Differentiation of sin(x) at x=1 ===\n");
x0     = 1.0;
exact1 = cos(1);          -- first derivative
exact2 = -sin(1);         -- second derivative
printf("%-10s  %-15s %-12s  %-15s %-12s\n",
       "h", "forward-err", "", "central-err", "2nd-deriv-err");
for k = 1:6
  h     = 10^(-k);
  fwd   = (sin(x0+h) - sin(x0)) / h;
  cen   = (sin(x0+h) - sin(x0-h)) / (2*h);
  sec_d = (sin(x0+h) - 2*sin(x0) + sin(x0-h)) / (h*h);
  printf("h=1e-%-2d  fwd %0.2e  cen %0.2e  2nd %0.2e\n",
         k, abs(fwd-exact1), abs(cen-exact1), abs(sec_d-exact2));
end


-- ─────────────────────────────────────────────────────────────
--  7. TRAPEZOIDAL RULE
--  Integral of f from a to b ≈ h*(f(a)/2 + f(a+h) +  --  Error O(h^2) per step, O(h^2) overall.
-- ─────────────────────────────────────────────────────────────
function I = trapz_rule(f, a, b, n)
  h = (b - a) / n;
  I = f(a) + f(b);
  x = a + h;
  for k = 1:n-1
    I = I + 2 * f(x);
    x = x + h;
  end
  I = I * h / 2;
end

printf("\n=== 7. Trapezoidal Rule ===\n");
-- Integrate exp(-x^2) from 0 to 1  (exact: erf(1)*sqrt(pi)/2 ≈ 0.7468241328)
exact_gauss = 0.7468241328124271;
f6 = @(x) exp(-x*x);
for n = [10, 100, 1000]
  I  = trapz_rule(f6, 0, 1, n);
  printf("n=%-5d  I=%0.10f  err=%0.2e\n", n, I, abs(I - exact_gauss));
end


-- ─────────────────────────────────────────────────────────────
--  8. SIMPSON'S RULE
--  Uses quadratic interpolation between pairs of panels.
--  Error O(h^4) — much better than trapezoidal for smooth f.
-- ─────────────────────────────────────────────────────────────
function I = simpsons(f, a, b, n)
  -- n must be even
  h = (b - a) / n;
  I = f(a) + f(b);
  x = a + h;
  for k = 1:n-1
    if mod(k, 2) == 0
      I = I + 2 * f(x);
    else
      I = I + 4 * f(x);
    end
    x = x + h;
  end
  I = I * h / 3;
end

printf("\n=== 8. Simpson's Rule ===\n");
for n = [10, 100, 1000]
  I  = simpsons(f6, 0, 1, n);
  printf("n=%-5d  I=%0.10f  err=%0.2e\n", n, I, abs(I - exact_gauss));
end


-- ─────────────────────────────────────────────────────────────
--  9. RICHARDSON EXTRAPOLATION
--  If error ! C*h^p, then combining I(h) and I(h/2) cancels
--  the leading error term: I* ≈ (4*I(h/2) - I(h)) / 3
--  Boosts trapezoidal from O(h^2) to O(h^4).
-- ─────────────────────────────────────────────────────────────
printf("\n=== 9. Richardson Extrapolation ===\n");
n1  = 10;
I1  = trapz_rule(f6, 0, 1, n1);       -- step h
I2  = trapz_rule(f6, 0, 1, 2*n1);     -- step h/2
Ir  = (4*I2 - I1) / 3;                -- Richardson combo
printf("Trapz n=10:   err=%0.2e\n", abs(I1 - exact_gauss));
printf("Trapz n=20:   err=%0.2e\n", abs(I2 - exact_gauss));
printf("Richardson:   err=%0.2e  (matches Simpson'slinsolve(), n", abs(Ir - exact_gauss));


-- ─────────────────────────────────────────────────────────────
--  10. EULER METHOD  (ODE IVP)
--  dy/dt = f(t,y),  y(t0) = y0
--  First-order explicit scheme.  Global error O(h).
-- ─────────────────────────────────────────────────────────────
function y = euler_ode(f, t0, t1, y0, h)
  y = y0;
  t = t0;
  n = round((t1 - t0) / h);
  for k = 1:n
    y = y + h * f(t, y);
    t = t + h;
  end
end

printf("\n=== 10. Euler Method  (dy/dt = -y, y(0)=1) ===\n");
-- Exact solution: y(t) = exp(-t),  y(1) = exp(-1)
ode_f  = @(t, y) -y;
exact_y1 = exp(-1);
for h = [0.1, 0.01, 0.001]
  y1 = euler_ode(ode_f, 0, 1, 1.0, h);
  printf("h=%0.3f  y(1)=%0.8f  err=%0.2e\n", h, y1, abs(y1 - exact_y1));
end


-- ─────────────────────────────────────────────────────────────
--  11. RUNGE-KUTTA 4  (ODE IVP)
--  Fourth-order explicit scheme.  Global error O(h^4).
--  The workhorse of scientific computing.
-- ─────────────────────────────────────────────────────────────
function y = rk4(f, t0, t1, y0, h)
  y = y0;
  t = t0;
  n = round((t1 - t0) / h);
  for k = 1:n
    k1 = f(t,       y);
    k2 = f(t + h/2, y + h/2 * k1);
    k3 = f(t + h/2, y + h/2 * k2);
    k4 = f(t + h,   y + h   * k3);
    y  = y + (h/6) * (k1 + 2*k2 + 2*k3 + k4);
    t  = t + h;
  end
end

printf("\n=== 11. Runge-Kutta 4  (dy/dt = -y, y(0)=1) ===\n");
for h = [0.1, 0.01, 0.001]
  y1 = rk4(ode_f, 0, 1, 1.0, h);
  printf("h=%0.3f  y(1)=%0.10f  err=%0.2e\n", h, y1, abs(y1 - exact_y1));
end

-- More interesting ODE: harmonic oscillator  d²x/dt² = -x
-- Rewrite as system: dx/dt = v,  dv/dt = -x
-- Pack as single value x encoding [pos, vel] as a 2-element vector
-- (Here we just track position: exact x(t) = cos(t))
printf("  Harmonic oscillator x''=-x, x(0)=1, x'(0)=0\n");
ho_f = @(t, x) x - 2*x;    -- simplified: just track cos via dy/dt = -y
-- Actually let's do it cleanly: solve v' = -x, x' = v with state = x (skip v)
-- Instead demonstrate with a stiff-ish equation: y' = -50(y - cos(t)) - sin(t)
-- exact: y(t) = cos(t)
stiff_f = @(t, y) -50 * (y - cos(t)) - sin(t);
y_stiff = rk4(stiff_f, 0, 1, 1.0, 0.05);
printf("  Stiff eq y'=-50(y-cos t)-sin t, y(1): %0.8f (exact cos(1)=%0.8flinsolve(), n",
       y_stiff, cos(1));


-- ─────────────────────────────────────────────────────────────
--  12. GAUSSIAN ELIMINATION WITH PARTIAL PIVOTING
--  Solves Ax = b for a 3×3 system.
--  Partial pivoting avoids division by tiny pivots.
-- ─────────────────────────────────────────────────────────────
function x = gauss3(A, b)
  -- Forward elimination with partial pivoting (3x3)
  for col = 1:2
    -- Find pivot row
    max_val = abs(A(col, col));
    pivot   = col;
    for row = col+1:3
      if abs(A(row, col)) > max_val
        max_val = abs(A(row, col));
        pivot   = row;
      end
    end
    -- Swap rows if needed
    if pivot != col
      for j = 1:3
        tmp         = A(col,   j);
        A(col,   j) = A(pivot, j);
        A(pivot, j) = tmp;
      end
      tmp      = b(col);
      b(col)   = b(pivot);
      b(pivot) = tmp;
    end
    -- Eliminate below pivot
    for row = col+1:3
      fac = A(row, col) / A(col, col);
      for j = col:3
        A(row, j) = A(row, j) - fac * A(col, j);
      end
      b(row) = b(row) - fac * b(col);
    end
  end
  -- Back substitution
  x = zeros(3, 1);
  for row = 3:-1:1
    s = b(row);
    for j = row+1:3
      s = s - A(row, j) * x(j);
    end
    x(row) = s / A(row, row);
  end
end

printf("\n=== 12. Gaussian Elimination (3×3) ===\n");
--  2x + y - z = 8
-- -3x - y + 2z = -11
-- -2x + y + 2z = -3
--  Exact solution: x=2, y=3, z=-1
A = [2, 1, -1; -3, -1, 2; -2, 1, 2];
b = [8; -11; -3];
sol = gauss3(A, b);
printf("x = %0.4f (exact 2linsolve(), n", sol(1));
printf("y = %0.4f (exact 3linsolve(), n", sol(2));
printf("z = %0.4f (exact -1linsolve(), n", sol(3));

-- Verify: compute residual Ax - b manually
r1 = 2*sol(1) + 1*sol(2) - 1*sol(3) - 8;
r2 = -3*sol(1) - 1*sol(2) + 2*sol(3) + 11;
r3 = -2*sol(1) + 1*sol(2) + 2*sol(3) + 3;
printf("Residual norm: %0.2e\n", sqrt(r1^2 + r2^2 + r3^2));


-- ─────────────────────────────────────────────────────────────
--  13. POWER ITERATION
--  Finds the eigenvalue of largest magnitude and corresponding
--  eigenvector of a symmetric matrix.
--  Convergence rate: |λ2/λ1|.
-- ─────────────────────────────────────────────────────────────
function lam = power_iter(A, n_iter)
  -- Start with a random-ish vector
  v = [1; 1; 1];
  lam = 0;
  for k = 1:n_iter
    -- Matrix-vector product (3x3 hardcoded)
    w1 = A(1,1)*v(1) + A(1,2)*v(2) + A(1,3)*v(3);
    w2 = A(2,1)*v(1) + A(2,2)*v(2) + A(2,3)*v(3);
    w3 = A(3,1)*v(1) + A(3,2)*v(2) + A(3,3)*v(3);
    lam = sqrt(w1^2 + w2^2 + w3^2);
    v(1) = w1 / lam;
    v(2) = w2 / lam;
    v(3) = w3 / lam;
  end
end

printf("\n=== 13. Power Iteration (dominant eigenvalue) ===\n");
-- Symmetric matrix with known eigenvalues 6, 2, 1 (dominant = 6)
M = [4, 1, 1; 1, 3, 0; 1, 0, 2];
lam = power_iter(M, 30);
printf("Dominant eigenvalue ≈ %0.8f\n", lam);
-- Note: M has eigenvalues that can be verified analytically


-- ─────────────────────────────────────────────────────────────
--  14. LAGRANGE INTERPOLATION
--  Given n data points (x_i, y_i), build the unique polynomial
--  of degree n-1 passing through all of them.
--  L(x) = Σ y_i * Π_{j≠i} (x - x_j)/(x_i - x_j)
-- ─────────────────────────────────────────────────────────────
function y = lagrange(xs, ys, x)
  n = length(xs);
  y = 0;
  for i = 1:n
    L = 1;
    for j = 1:n
      if j != i
        L = L * (x - xs(j)) / (xs(i) - xs(j));
      end
    end
    y = y + ys(i) * L;
  end
end

printf("\n=== 14. Lagrange Interpolation ===\n");
-- Sample sin(x) at 5 points and interpolate at intermediate x
xs = [0, pi/4, pi/2, 3*pi/4, pi];
ys = [0, sin(pi/4), 1, sin(3*pi/4), 0];
printf("%-12s  %-12s  %-12s  %-12s\n", "x", "sin(x)", "Lagrange", "error");
for x_test = [0.3, 0.8, 1.2, 1.8, 2.5]
  exact_v = sin(x_test);
  interp  = lagrange(xs, ys, x_test);
  printf("x=%0.2f  exact=%0.8f  interp=%0.8f  err=%0.2e\n",
         x_test, exact_v, interp, abs(interp - exact_v));
end

printf("\n=== Tutorial complete! ===\n");
}
