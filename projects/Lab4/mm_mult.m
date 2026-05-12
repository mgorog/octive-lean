% mm_mult.m
% Manual matrix-matrix multiplication using triple nested loops.
% C = A * B  (no built-in matrix multiplication operator used).
%
% Input(s):   A (m×n), B (n×p)
% Output(s):  C (m×p)
%
% Date: February 20, 2026
% Programmer: Maximus

function C = mm_mult(A, B)
    [m, n] = size(A);
    [p, q] = size(B);
    
    if n ~= p
        error('Inner dimensions must agree for matrix multiplication');
    end
    
    C = zeros(m, q);          % pre-allocate
    
    for i = 1:m
        for j = 1:q
            for k = 1:n
                C(i, j) = C(i, j) + A(i, k) * B(k, j);
            end
        end
    end
end
