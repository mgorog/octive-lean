% test_all.m
% Comprehensive test script for pig, mv_mult, and mm_mult (all 4 matrix-matrix cases)
% Just type:   >> test_all

clc;
clear;
format short;

disp('================================');
disp('  TEST ALL FUNCTIONS - LAB 4');
disp('================================');
disp(' ');

%% 1. TEST PIG LATIN
disp('1. TESTING PIG LATIN FUNCTION (pig.m)');
test_words = {'hello', 'Bruce', 'apple', 'Octave', 'rhythm', 'A', 'why', ''};
for i = 1:length(test_words)
    w = test_words{i};
    p = pig(w);
    if isempty(w)
        disp(['  ''' w '''  (empty)  -->  ''' p '''']);
    else
        disp(['  ''' w '''  -->  ''' p '''']);
    end
end
disp(' ');

%% 2. TEST MATRIX-VECTOR
disp('2. TESTING MATRIX × VECTOR (mv_mult.m)');
A = [1 2 3; 4 5 6];
x = [7; 8; 9];
y_manual = mv_mult(A, x);
y_builtin = A * x;
disp('A =');      disp(A);
disp('x =');      disp(x);
disp('mv_mult result =');   disp(y_manual);
disp('Built-in A*x  =');    disp(y_builtin);
E_mv = y_manual - y_builtin;
disp('Difference (should be zero):'); disp(E_mv);
disp(' ');

%% 3. TEST MATRIX-MATRIX (4 cases)
disp('3. TESTING MATRIX × MATRIX (mm_mult.m) - 4 different cases');
format long;

% Test 1: 2×2 × 2×2
disp('Test 1: 2×2 × 2×2');
A1 = [1 2; 3 4];  B1 = [5 6; 7 8];
C1m = mm_mult(A1, B1);  C1b = A1 * B1;  E1 = C1m - C1b;
disp('Manual:');  disp(C1m);  disp('Built-in:'); disp(C1b);  disp('Error:'); disp(E1);

% Test 2: 2×3 × 3×2
disp('Test 2: 2×3 × 3×2');
A2 = [1 2 3; 4 5 6];  B2 = [7 8; 9 10; 11 12];
C2m = mm_mult(A2, B2);  C2b = A2 * B2;  E2 = C2m - C2b;
disp('Manual:');  disp(C2m);  disp('Built-in:'); disp(C2b);  disp('Error:'); disp(E2);

% Test 3: 3×1 × 1×3
disp('Test 3: 3×1 × 1×3');
A3 = [1; 2; 3];  B3 = [4 5 6];
C3m = mm_mult(A3, B3);  C3b = A3 * B3;  E3 = C3m - C3b;
disp('Manual:');  disp(C3m);  disp('Built-in:'); disp(C3b);  disp('Error:'); disp(E3);

% Test 4: 3×2 × 2×4
disp('Test 4: 3×2 × 2×4');
A4 = [1 2; 3 4; 5 6];  B4 = [1 2 3 4; 5 6 7 8];
C4m = mm_mult(A4, B4);  C4b = A4 * B4;  E4 = C4m - C4b;
disp('Manual:');  disp(C4m);  disp('Built-in:'); disp(C4b);  disp('Error:'); disp(E4);

format short;
disp('====================================');
disp('ALL TESTS COMPLETED SUCCESSFULLY!');
disp('====================================');
