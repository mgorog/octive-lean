import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `mv_mult.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
-- mv_mult.m
-- Manual matrix-vector multiplication using only loops (no built-in * operator).
-- y = A * x  where A is m×n matrix, x is n×1 column vector.
--
-- Input(s):   A (matrix), x (column vector)
-- Output(s):  y (column vector)
--
-- Date: February 20, 2026
-- Programmer: Maximus

function y = mv_mult(A, x)
    [m, n] = size(A);
    y = zeros(m, 1);          -- pre-allocate result
    
    for i = 1:m
        for j = 1:n
            y(i) = y(i) + A(i, j) * x(j);
        end
    end
end
}
