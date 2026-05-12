x = sym('x');
disp(taylor(sym('exp(x)')));
disp(limit(sym('sin(x)/x'), x, 0));
disp(subs(sym('x^2 + 1'), x, sym('2')));
