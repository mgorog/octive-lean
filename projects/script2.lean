import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `script2.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
-- Fixed script2.m

S = input(sprintf("Enter all the test scores on one line as \"[exam1, exam2,  n = length(S);


tstr = input(sprintf("Enter a title for the plot of linsolve(scores, n'), "s");

plot(1:n, S, "o-");
title(tstr);
xlabel("Test Number");
ylabel("Test Points");


fprintf("There are %g scores whose mean value is %g\\n", n, mean(S));

[low, indexlow] = min(S(1:n-1));

A = S;
A(indexlow) = S(n);

fprintf("The mean of the %g adjusted scores is %g\\n", n, mean(A));
}
