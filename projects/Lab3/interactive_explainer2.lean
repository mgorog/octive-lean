import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `interactive_explainer2.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
-- interactive_explainer2.m
-- FIXED VERSION: Corrected matrix multiplication with transpose
-- Now all three methods agree on the correct total cost: 49016.832000
-- The previous version had an error: C * A * P was mathematically incorrect
-- due to matrix orientation (rows=products, columns=materials).
-- Correct is C * (A' * P) because we need to sum over products for each material.

function interactive_explainer2()

clc;
clear functions;

disp("=================================================================");
disp("    Interactive Explainer: Production Cost Matrix Problem      ");
disp("=================================================================");
disp("FIXED VERSION: All three methods now agree (transpose added).");
disp("We will:");
disp("  - Explain the input matrix");
disp("  - Show the required function (with correct transpose)");
disp("  - Compute the total cost three different ways");
disp("  - Verify all methods agree");
disp("  - Show operation counts");
disp("Press Enter at each pause to continue.");
disp("=================================================================");

input("\\nPress Enter to begin...");

-- ================================================================
-- Explain the matrix
-- ================================================================
datain = [20, 30, 0, 70.5; 10, 50, 70, 90.3; 5, 7, 2, 120.8; 3.1, 1.59, 4.28, 0];

disp("\\n === Input Matrix (datain) ===================================");
disp("Rows 1-3: Products 1-3");
disp("Columns 1-3: Units of material 1-3 per unit of product");
disp("Column 4: Units produced of each product");
disp("Row 4 (cols 1-3): Cost per unit of each material");
disp("Entry (4,4): Will be filled with total production cost");
disp(datain);

input("\\nPress Enter to see the required function...");

-- ================================================================
-- Show the function (now with correct transpose)
-- ================================================================
disp("\\n === Required Function: production_cost =======================");
disp("Uses matrix multiplication with transpose (A') because rows=products, columns=materials");
code_func = { "function dataout = production_cost(datain)", "    dataout = datain;", "    A = datain(1:3,1:3);   % product rows x material columns", "    P = datain(1:3,4);     % production vector", "    C = datain(4,1:3);     % cost row vector", "    total = C * (A' * P);  % Correct: transpose to sum over products per material", "    dataout(4,4) = total;", "end" };
for k = 1:length(code_func)
    disp(["   ", cellget(code_func, k)]);
end

input("\\nPress Enter to run the function...");

dataout = production_cost(datain);
disp("\\nOutput matrix with total cost in (4,4):");
disp(dataout);
fprintf("Total production cost: %0.6f\\n", dataout(4,4));

input("\\nPress Enter for the three computation methods...");

-- ================================================================
-- Three methods (all now correct)
-- ================================================================
disp("\\n === Three Ways to Compute the Total Cost ====================");
disp("Note: Matrix methods use A' (transpose) for correct summation.");

disp("\\nMethod 1: Direct matrix multiplication C * (A' * P)");
code1 = { "total1 = C * (A' * P);" };
for k = 1:length(code1)
 disp(["   ", cellget(code1, k)])
 end

disp("\\nMethod 2: Intermediate material totals (A'*P first, then C*that)");
code2 = { "material_totals = A' * P;", "total2 = C * material_totals;" };
for k = 1:length(code2)
 disp(["   ", cellget(code2, k)])
 end

disp("\\nMethod 3: Pure scalar double loops (explicit summations)");
code3 = { "total3 = 0;", "for prod = 1:3", "    for mat = 1:3", "        total3 = total3 + A(prod,mat) * C(mat) * P(prod);", "    end", "end" };
for k = 1:length(code3)
 disp(["   ", cellget(code3, k)])
 end

input("\\nPress Enter to execute all three methods...");

A = datain(1:3,1:3);
P = datain(1:3,4);
C = datain(4,1:3);

-- Method 1 (correct)
total1 = C * (htranspose(A) * P);

-- Method 2 (correct)
material_totals = htranspose(A) * P;
total2 = C * material_totals;

-- Method 3 (already correct)
total3 = 0;
for prod = 1:3
    for mat = 1:3
        total3 = total3 + A(prod,mat) * C(mat) * P(prod);
    end
end

disp("\\nResults:");
fprintf("Method 1 (C*(A'*P))      : %0.6f\\n", total1);
fprintf("Method 2 (material totals): %0.6f\\n", total2);
fprintf("Method 3 (scalar loops)   : %0.6f\\n", total3);

tol = 1e-10;
if abs(total1-total2) < tol && abs(total1-total3) < tol
    disp("All three methods agree perfectly on 49016.832000!");
else
    disp("Error: Methods disagree.");
end

input("\\nPress Enter for operation counts...");

-- ================================================================
-- Operation counts
-- ================================================================
disp("\\n === Operation Counts (for n=3) ===============================");
n = 3;
mult = n^2 + n;                    -- n^2 for A'*P, n for C*result
add  = n*(n-1) + (n-1);            -- additions in each mult

fprintf("Multiplications: %d\\n", mult);
fprintf("Additions      : %d\\n", add);

disp("\\nGeneral case (n products, n materials):");
disp("Multiplications: n^2 + n");
disp("Additions      : n^2 - 1");
disp("Transpose adds no significant operations.");
disp("All methods have the same O(n^2) complexity.");

disp("\\n === Done! Correct total production cost is 49016.832000 ===");

end  -- end of main function

-- ================================================================
-- Subfunction: the required production_cost function (corrected)
-- ================================================================

function dataout = production_cost(datain)
    dataout = datain;
    A = datain(1:3,1:3);
    P = datain(1:3,4);
    C = datain(4,1:3);
    total = C * (htranspose(A) * P);   -- Corrected with transpose
    dataout(4,4) = total;
end
}
