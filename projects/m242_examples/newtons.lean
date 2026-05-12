import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `newtons.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
function x = newtons(f,df,guess,tol,maxstep,show)
-- Carries out up to maxstep iterations of newtons method
-- for approximation of a root of f(x) = 0.
-- The problem function (f) and its derivative (df)
-- are to be given as m-file function name strings or handles.
-- The iteration starts with initial iterate:   guess.
-- The iteration terminates if abs(step) and abs(f(x)) fall below tol.
-- OR if maxstep steps have been taken.
-- If show is present, interations are printed (in format long e if show>1)
-- Usage Example:
--   >> f1=@(x) x.^3 - 7; df1=@(x) 3*x^2;
--   >> xstar = newtons(f1,df1,20,1.e-12,100,2)   1.912931182772399e+00
-- Programmer:  B N Lundberg. March 11, 2008. Updated March 31, 2025 
-- Reference: Stewart, Calculus, Sec. 4.8             

-- Initialize while loop variables

k = 0;           -- step counter
step = tol+1;    -- fake step size to get into loop
x = guess;       -- initialize iteration variable
y  = feval(f,x); -- compute f at current iterate

while abs(step)>=tol && abs(y)>=tol && k <=maxstep
    
    -- compute df at current iterate  
    yp = feval(df,x); 
    
    -- compute and take new step
    step = -linsolve(yp, y;
    x = x + step;
    
    -- compute f at new iterate
    y  = feval(f,x);
    
    -- update counter
    k = k + 1;
    
    -- display iterates only if 6th input argument is present
    if nargin>5
        if show<2
            fprintf("x_%2i = %g     f(x_%2i) = %g\\n", k,x,k,y)
        else
            fprintf("x_%2i = %18.17g     f(x_%2i) = %18.17g\\n", k,x,k,y)
        end
    end
    
end

-- check for and report failure to satisfy tolerance
if k > maxstep
    disp(["Stopping tolerance not satified in ",num2str(maxstep)," iteratons"])
end
}
