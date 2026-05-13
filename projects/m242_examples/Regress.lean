import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `Regress.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
function [a,b,r,rsq,residuals,xbar,ybar,stdx,stdy] = plot_fit(x,y,xstr,ystr,ttlstr,axesabcd,nfit)
-- Input: x and y are equal length rows of numbers to be plotted

-- if nargin>6, make and plot a polynomial fit of degree nfit
--    including a residual subplot
--    if nfit=1, linear regression with stats:
--               means, stddev, and correlation of x, y  
--          Regression coef in yhat = a+bx, correlations r and rsq=r^2,
--          plot of data with y=a+bx and (xbar,ybar
--          plot residuals 
if isa(y, "function_handle")  -- checks if y is a function
    yx=y(x);

else
    yx=y;
end

if nargin <= 5  -- single basic data plot
    plot(x,yx,"b.",x,yx,"g")
    if nargin>2
 xlabel(xstr)
end
    if nargin>3
 ylabel(ystr)
end
    if nargin>4
 title(ttlstr)
end
end
if nargin>5    -- linear regression with residuals and stats
    
   if nfit == 1
-- 1-var stats
xbar = mean(x);
ybar = mean(yx);
stdx=std(x);
stdy=std(yx);
-- Correlation
X=[htranspose(x), htranspose(yx)];
R=corrcoeff(X);
r=R(1,2);
rsq=r^2;
   end
   c=polyfit(x,yx,nfit);
   yhat=polyval(c,x);
   mx=minx(x);Mx=max(x);
   h=0.05*(Mx-mx); -- increase width by 10%
   a=mx-h; b=Mx+h; -- plot over interval [a, b]
   xt=a:h/10:b;
   yt=polyval(c,xt);
   


v=axis

v =

    -2     4     1     5

vn=[-3, 5, -1, 7];
axis(vn)
axis equal
axi
axis(v)
axis(vn)
axis square
title("Scatter Plot with yhat= a + bx")
t=-3:5;
yt=2.7153 + 0.3869*t;
plot(t,yt)
xbar=mean(x);
 ybar=mean(y);
 plot(xbar,ybar,"p")
yhat=2.7153 + 0.3869*x;
es=y-yhat

es =

   0.897800000000000   1.897800000000000  -1.876000000000000   0.058500000000000  -1.715300000000000   0.737100000000000

format short
es

es =

    0.8978    1.8978   -1.8760    0.0585   -1.7153    0.7371

subplot(2,1,2)
 plot(x,es,"d")
xlabel("x")
ylabel("residuals (e = y - yhat")
ve=vn

ve =

    -3     5    -1     7

ve(3)=-2;
ve(4)=2;
axis(ve)
ve(3)=-3;
ve(4)=3;
axis square
axis(ve)
subplot(2,1,2)
 plot(x,es,"d")
xlabel("x")
ylabel("residuals (e = y-yhat)")
axis square
axis(ve)
help stdev

end

x=[1, 1, 3, -2, 0, 4];y=[4, 5, 2, 2, 1, 5];
end

}
