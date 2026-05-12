x = sym('x');
f = x^2 + 2*x + 1;
disp(f);
disp(diff(f, x));
disp(int(diff(f, x), x));
