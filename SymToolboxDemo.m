% Symbolic Math Toolbox - cheat sheet walkthrough.
% Each labeled block produces one line of output.

x = sym('x'); y = sym('y'); z = sym('z'); t = sym('t');
a = sym('a'); b = sym('b'); k = sym('k'); n = sym('n');

% Calculus
printf("diff:        "); disp(diff(sym('sin(x^2 + t)'), x));
printf("int indef:   "); disp(int(sym('x/(1+z^2)'), z));
printf("int def:     "); disp(int(sym('x^2'), x, 0, 1));
printf("limit left:  "); disp(limit(sym('1/x'), x, 0, "left"));
printf("taylor:      "); disp(taylor(sym('exp(-x)')));
printf("series:      "); disp(series(sym('1/sin(x)'), x));
printf("symsum:      "); disp(symsum(k, k, 0, n - 1));

printf("gradient:    "); disp(gradient(sym('x*y + 2*z*x'), sym('[x, y, z]')));
printf("jacobian:    "); disp(jacobian(sym('[x*y*z, y, x+z]'), sym('[x, y, z]')));
printf("hessian:     "); disp(hessian(sym('x*y + 2*z*x'), sym('[x, y, z]')));
printf("laplacian:   "); disp(laplacian(sym('1/x + y^2 + z^3'), sym('[x, y, z]')));

% Algebra
printf("double pi:   "); disp(double(sym('pi')));
printf("vpa pi 30:   "); disp(vpa(sym('pi'), 30));
printf("subs:        "); disp(subs(sym('a^3 + b'), a, 2));
printf("solve poly:  "); disp(solve(sym('x^2 - 4'), x));
printf("solve sys:   "); disp(solve(sym('[u + v - a, u - v - b]'), sym('[u, v]')));
printf("isolate:     "); disp(isolate(sym('a*x^2 + b*x + c'), x));
printf("lhs:         "); disp(lhs(sym('Eq(x^2, y^2)')));
printf("rhs:         "); disp(rhs(sym('Eq(x^2, y^2)')));
printf("simplify:    "); disp(simplify(sym('sin(x)^2 + cos(x)^2')));
printf("expand:      "); disp(expand(sym('(x+1)^3')));
printf("factor:      "); disp(factor(sym('x^2 - 1')));
printf("collect:     "); disp(collect(sym('x*y + x^2 + 2*x*y + 3'), x));
printf("rewrite:     "); disp(rewrite(sym('tan(x)/cos(x)'), "sin"));
printf("resultant:   "); disp(resultant(sym('x^2 + y'), sym('x - 2*y'), x));

% ODE - symfun() registers a SymPy Function so f(t) parses as f-of-t
symfun('f');
printf("dsolve:      "); disp(dsolve(sym('Eq(Derivative(f(t), t), a*f(t))'), sym('f(t)')));

% Functions
printf("piecewise:   "); disp(piecewise(sym('x < 0'), -1, sym('x >= 0'), 2));

% Output formats
printf("latex:       "); disp(latex(sym('x^2 + y^2')));
