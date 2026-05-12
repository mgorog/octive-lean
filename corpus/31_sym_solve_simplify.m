x = sym('x');
disp(solve(x^2 - 4, x));
disp(simplify(sym('sin(x)^2 + cos(x)^2')));
disp(factor(sym('x^2 - 1')));
disp(expand(sym('(x+1)^3')));
