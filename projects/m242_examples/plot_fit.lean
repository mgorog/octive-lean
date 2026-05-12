import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `plot_fit.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
function [reg_slope,reg_intcpt,r,rsq,resid,xbar,ybar,stdx,stdy] = plot_fit(x,y,xstr,ystr,ttlstr,nfit)
-- Input: x and y are equal length rows of numbers to be plotted
--          OR  y is a function handle to be evaluated at x values

-- if nargin>5, make and plot a polynomial fit of degree nfit
--    including a residual subplot
--    if nfit=1, linear regression with stats:
--               means, stddev, and correlation of x, y
--          Regression coef in yhat = a+bx, correlations r and rsq=r^2,
--          plot of data with y=a+bx and (xbar,ybar
--          plot residuals
-- Sample >>plot_fit(-1:0.1:10,@cos,"\\theta (rad)","y-axis","y = cos \\theta",6)
-- Date: 2-24-2025    Programmer; B. Lundberg

-- Establish plotting x interval
mx=min(x);Mx=max(x);
h=0.05*(Mx-mx); -- increase width by 10%
a=mx-h; b=Mx+h; -- plot over horizontal interval [a, b]

if isa(y, "function_handle")  -- checks if y is a function handle
    yx=y(x); -- computes y values from the function passed in var y
else
    yx=y; -- in this case y is assumed to contain numbers
end

my=min(yx);My=max(yx);
hy=0.05*(My-my); -- increase height by 10%
c=my-hy; d=My+hy; -- plot over vertical interval [c, d]


if nargin <=5  -- single basic data plot
else
    subplot(2,1,1)
end
plot(x,yx,"g.",x,yx,"k-")
axis([a,b,c,d]); -- changes from default axis bounds
if nargin>2, xlabel(xstr),end
if nargin>3, ylabel(ystr),end
if nargin>4, title(ttlstr),end

-- 1-var stats
if nargout >=6, xbar = mean(x);end
if nargout >=7, ybar = mean(yx);end
if nargout >=8, stdx=std(x);end
if nargout >=9, stdy=std(yx);end
-- Correlation
if nargout >=3,
    X=[x' yx'];
    R=corrcoef(X);
    r=R(1,2);
end
if nargout >=4,rsq=r^2; end

-- Polynomial Regression
if nargin>5    -- linear regression with residuals and stats
    c=polyfit(x,yx,nfit);
    reg_slope = c(end-1);reg_intcpt = c(end); -- linear part if nfit>1
    yhat=polyval(c,x);
    resid=yx-yhat; -- residuals
    xt=a:h/10:b;
    yt=polyval(c,xt);
    
    hold
    plot(xt,yt,"r")
    legend("input data plot","input points",["degree ",num2str(nfit)," fit"])
    
    subplot(2,1,2)  -- plot residuals (x,ex)
    
    plot(x,resid,"m.")
    ve=axis;ce=ve(3);de=ve(4);
    axis([a,b,ce,de]); -- changes from default axis bounds
    if nargin>2, xlabel(xstr),end
    if nargin>3, ylabel(["Degree ",num2str(nfit)," residuals(e=y-yhat)"]),end
    subplot(2,1,1), hold off
    subplot(2,1,2), hold off
end
hold off

end
}
