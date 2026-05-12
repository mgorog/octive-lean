import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `test.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
-- =====================================================
-- Literate Interactive Octave Tutorial
-- Recursion, Subplots, Semilogy, and Taylor Approximation
-- Run this script with:  test_tutorial
-- =====================================================

clc;
disp("=====================================================");
disp("  Welcome to the Interactive Octave Tutorial!");
disp("  We will explore recursion, subplots, semilogy plots,");
disp("  and the cosine Taylor approximation step by step.");
disp("=====================================================");
disp(" ");
input("Press Enter to begin the tutorial clc;

-- ====================== SECTION 1 ======================
disp("=== SECTION 1: Recursive Factorial ===");
disp(" ');
disp("A recursive function calls itself until it reaches a base case.");
disp("Factorial definition:");
disp("   0! = 1");
disp("   n! = n × (n-1)!   for n > 0");
disp(" ");
disp("We define it as a named function (anonymous recursion does not work in Octave).");

function res = fac(n)
    if n == 0
        res = 1;
    elseif n > 0
        res = n * fac(n - 1);
    else
        error("Factorial is only defined for non-negative integers.");
    end
end

disp(" ");
n = input("Enter a non-negative integer n (try 0 to 10): ");
while n < 0 || mod(n,1) != 0
    disp("Please enter a valid non-negative integer.");
    n = input("Enter n again: ");
end

result = fac(n);
disp(" ");
disp(["Result: fac(" num2str(n) ') = " num2str(result)]);
disp(" ');
input("Press Enter to continue to the next section clc;

-- ====================== SECTION 2 ======================
disp("=== SECTION 2: Recursive Power (Exponentiation by Squaring) ===");
disp(" ');
disp("This is an efficient recursive way to compute A^K in O(log K) steps.");
disp("Base case: A^0 = 1");
disp("Even K: (A^(K/2))^2");
disp("Odd K: A × (A^((K-1)/2))^2");

function pow = recursive_power(A, K)
    if K == 0
        pow = 1;
    elseif mod(K, 2) == 0
        half = recursive_power(A, K/2);
        pow = half * half;
    else
        half = recursive_power(A, (K-1)/2);
        pow = A * half * half;
    end
end

disp(" ");
A = input("Enter base A (e.g. 2): ");
K = input("Enter exponent K (non-negative integer, e.g. 0 to 20): ");
while K < 0 || mod(K,1) != 0
    disp("K must be a non-negative integer.");
    K = input("Enter K again: ");
end

result = recursive_power(A, K);
disp(" ");
disp(["Result: ", num2str(A) '^' num2str(K) ' = " num2str(result)]);
disp(" ');
input("Press Enter to continue clc;

-- ====================== SECTION 3 ======================
disp("=== SECTION 3: Subplots ===");
disp(" ');
disp("subplot(rows, cols, index) divides a figure into a grid.");
disp("Example: 2 rows × 3 columns → 6 panels.");
disp("We will plot sine and cosine in positions 1 and 4.");
disp(" ");

figure(1);
x = linspace(0, 2*pi, 200);
y_sin = sin(x);
y_cos = cos(x);

subplot(2, 3, 1);
plot(x, y_sin, "b-", "LineWidth", 1.5);
title("Sine Wave");
xlabel("x");
ylabel("sin(x)");
grid on;

subplot(2, 3, 4);
plot(x, y_cos, "r-", "LineWidth", 1.5);
title("Cosine Wave");
xlabel("x");
ylabel("cos(x)");
grid on;

disp("Figure 1 has been created.");
disp("Check the plot window!");
disp(" ");
input("Press Enter to continue to semilogy clc;

-- ====================== SECTION 4 ======================
disp("=== SECTION 4: Semilogy Plot ===");
disp(" ');
disp("semilogy(x, y) uses a logarithmic y-scale.");
disp("Perfect for showing errors that span many orders of magnitude.");
disp(" ");

figure(2);
x_sem = linspace(0, 10, 200);
y_sem = exp(-x_sem);

semilogy(x_sem, y_sem, "g-", "LineWidth", 1.5);
title("Semilogy Plot of exp(-x)");
xlabel("x");
ylabel("log(y)");
grid, on;

disp("Figure 2 has been created.");
disp("Notice how the exponential decay becomes a straight line on log scale.");
disp(" ");
input("Press Enter to continue to the application problem clc;

-- ====================== SECTION 5 ======================
disp("=== SECTION 5: Application - Taylor Approximation of cos(2x) ===");
disp(" ');
disp("We compare exact cos(2x) with its Taylor series approximation:");
disp("cos(2x) ≈ 1 - (2x)^2/2! + (2x)^4/4! - (2x)^6/6!");
disp("Over x = -2π to 2π (≈ ±2 periods).");
disp(" ");

-- Let user choose the Taylor order (more interactive!)
order = input("How many terms do you want in the Taylor series? (default 4 = up to x^6): ");
if isempty(order) || order < 1
    order = 4;
end

x_app = linspace(-2*pi, 2*pi, 300);
y_exact = cos(2*x_app);

-- Build Taylor series dynamically
y_approx = 1;  -- constant term
sign = -1;
for k = 1:order
    term = sign * (2*x_app).^(2*k) / factorial(2*k);
    y_approx = y_approx + term;
    sign = -sign;
end

e = abs(y_approx - y_exact);

figure(3);

-- Subplot 1: Comparison
subplot(2, 1, 1);
plot(x_app, y_exact, "b-", "LineWidth", 2); hold on;
plot(x_app, y_approx, "r--", "LineWidth", 2);
title(["Exact vs Taylor approx (order " num2str(order) ')']);
xlabel("x");
ylabel("y");
legend("Exact cos(2x)", "Approximation");
grid on;

-- Subplot 2: Error on semilogy
subplot(2, 1, 2);
semilogy(x_app, e, "m-", "LineWidth", 2);
title("Absolute Error on log scale");
xlabel("x");
ylabel("log(|approx - exact|)");
grid on;

disp("Figure 3 has been created.");
disp("Observe how the error grows away from x = 0.");
disp("Higher order = better approximation near zero.");
disp(" ");
input("Press Enter to finish the tutorial clc;

disp("=====================================================");
disp("Tutorial complete!");
disp("You now have three figure windows open.');
disp("You can close them manually or type close all.");
disp(" ");
disp("Would you like to run the tutorial again?");
again = input("Type \"yes\" or press Enter to quit: ", "s");
if, strcmpi(again, "yes")
 run("test_tutorial.m"); -- Change filename if you save it differently
else
 disp("Thank you for learning with this interactive script!");
end
}
