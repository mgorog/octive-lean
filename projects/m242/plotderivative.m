function dxdt = plotderivative(f, a, b, n)
% Plots numerical derivative of f over [a,b] using n intervals
h = (b - a) / n;
x = a + (0:n-1) * h;  % Evaluation points for derivatives
dxdt = zeros(1, n);
for i = 1:n
    dxdt(i) = (f(x(i) + h) - f(x(i))) / h;
end
plot(x, dxdt, 'b-');
title('Numerical Derivative of f');
xlabel('x');
ylabel('df/dx');
grid on;
axis equal;  % Ensures equal scaling if ranges align
end
