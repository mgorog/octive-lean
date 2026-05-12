import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `slope_test.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
-- slope_test.m
-- Tests all input modes for slope.m, including special cases (NaN, Inf).
-- Assumes slope.m is in the current directory or path.
clear all;  -- Clear workspace and globals

-- Test 4-argument mode: scalars
disp("4-arg scalars: slope(1,2,3,6) = (6-2)/(3-1) = 2");
m = slope(1,2,3,6);
disp(m);

disp("4-arg vertical: slope(1,2,1,6) = Inf");
m = slope(1,2,1,6);
disp(m);

disp("4-arg same points: slope(1,2,1,2) = NaN");
m = slope(1,2,1,2);
disp(m);

-- Test 4-argument mode: vectors (length 2)
disp("4-arg vectors: slope([1,4],[2,5],[3,6],[6,9]) = [2,2]");
m = slope([1,4],[2,5],[3,6],[6,9]);
disp(m);

-- Test 2-argument mode: n x 2 matrices
global P Q  -- Declare before assignment to avoid warnings
P = [1,2; 4,5];  -- Point1: (1,2), Point2: (4,5)
Q = [3,6; 6,9];  -- Point1: (3,6), Point2: (6,9)
disp("2-arg: slope(P,Q) = [ (6-2)/(3-1)=2, (9-5)/(6-4)=2 ]");
m = slope(P,Q);
disp(m);

-- Test 0-argument mode: globals X1,Y1,X2,Y2 (vectors)
global X1 Y1 X2 Y2  -- Declare before assignment
X1 = [1;4]; Y1 = [2;5]; X2 = [3;6]; Y2 = [6;9];  -- Column vectors to trigger 4-arg
disp("0-arg with X1,Y1,X2,Y2 (vectors): slope = [2,2]");
m = slope;
disp(m);

-- Test 0-argument mode: globals X1,Y1 with 2 columns
clear global X1 Y1 X2 Y2  -- Reset globals
global X1 Y1  -- Declare before assignment
X1 = [1,2; 4,5];  -- n x 2
Y1 = [3,6; 6,9];  -- n x 2
disp("0-arg with X1,Y1 as n x 2: slope = [2,2]");
m = slope;
disp(m);

-- Test 0-argument mode: globals P,Q when X1 empty
clear global X1 Y1 X2 Y2
global X1 P Q  -- Declare before assignment
X1 = [];  -- Empty to trigger P,Q
P = [1,2; 4,5];
Q = [3,6; 6,9];
disp("0-arg with X1 empty, using P,Q: slope = [2,2]");
m = slope;
disp(m);

-- Test 0-argument mode: globals P,Q when X2 empty
clear global X1 Y1 X2 Y2
global X2 P Q  -- Declare before assignment
X2 = [];  -- Empty to trigger P,Q
P = [1,2; 4,5];
Q = [3,6; 6,9];
disp("0-arg with X2 empty, using P,Q: slope = [2,2]");
m = slope;
disp(m);
}
