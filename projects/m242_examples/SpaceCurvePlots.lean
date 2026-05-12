import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `SpaceCurvePlots.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
function [r,T1,N1,B1,kappa1,R1,Rot]=SpaceCurvePlots(t1,t2,r,rp,rpp,ttl)
-- Plots apace curve r(t) over [t1,t2]
-- by B.N. Lundberg  9-19-2024 for Math 325 Class
-- Computes and plots the curve r and its curvature and radius
-- IF functions handles for r, rp, rpp are given in input list
-- IF these are NOT supplied,
--    Math 325   Problem 13.3 #20 r, rp, rpp
--    are used,  computed and r is plotted and also
--    the curvature and radius of curvature along the curve
--    The osculating circle and center of curvature at t2=1
--    The TNB frame is plotted for t=0 and 1.
ttl="Space Curve and TNB Frames"; -- default title.
if nargin<3
-- Math 325   Problem 13.3 #20
r=@(t) [t; 0.5*t.^2; t.^2];
rp=@(t) [ones([1,length(t)]); t; 2*t];
rpp=@(t) [zeros([1,length(t)]); ones([1,length(t)]); 2*ones([1,length(t)])];
ttl="Math 325: Sec 13:3 # 20";
end

t=linspace(t1-2,t2+2,101);
rt = r(t);
hold off
plot3(rt(1,:),rt(2,:),rt(3,:))
hold
xlabel("x"),ylabel("y"),zlabel("z")
title(ttl);
-- TNB Frames at t1 and t2
T0=[1,0,0]';N0=[0,1/sqrt(5),2/sqrt(5)]';B0=[0,-2/sqrt(5),1/sqrt(5)]';
quiver3(0,0,0,1,0,0,"g") -- T
quiver3(0,0,0,0,1/sqrt(5),2/sqrt(5),"r--") -- N
quiver3(0,0,0,0,-2/sqrt(5),1/sqrt(5),"b-.") -- B

T1=[1,1,2]'/sqrt(6);N1=[-5,1,2]'/sqrt(30);B1=[0,-2/sqrt(5),1/sqrt(5)]';
quiver3(1,0.5,1,1/sqrt(6),1/sqrt(6),2/sqrt(6),"g") -- T
quiver3(1,0.5,1,-5/sqrt(30),1/sqrt(30),2/sqrt(30),"r")  -- N
quiver3(1,0.5,1,0,-2/sqrt(5),1/sqrt(5),"b")  -- Bh

grid
H1=gcf;

-- Curvature and Osculating Circle at t1
rpt=rp(t);
rppt=rpp(t);
norms_rp3 = zeros([1,length(t)]);
norms_rpXrpp = zeros([1,length(t)]);
kappa = zeros([1,length(t)]);


for n=1:length(rpt)
  norms_rp3(n) = norm(rpt(:,n),2)^3; 
  norms_rpXrpp(n) = norm(cross(rpt(:,n),rppt(:,n)),2);
  kappa(n)=norms_rpXrpp(n)/norms_rp3(n);
end
figure
subplot(2,1,1)
plot(t,kappa,"b")
title("\\kappa and R for r(t)= [t; 0.5*t.^2; t.^2]");
xlabel("t"),ylabel("\\kappa, curvature")
hold off
subplot(2,1,2)
plot(t,1./kappa,"r")
xlabel("t"),ylabel("R, radius of curvature")
hold off

-- Osculating Circle
rp1=rp(1);rpp1=rpp(1);
norm_rp31 = norm(rp1,2)^3; 

norm_rpXrpp1 = norm(cross(rp1,rpp1),2);
kappa1=norm_rpXrpp1/norm_rp31;
R1=1/kappa1;
theta=linspace(0,2*pi,50);
circR = [R1*cos(theta);R1*sin(theta);zeros([1,length(theta)])];
-- Construct Reflection of B1 to k
-- nhat = [0;0;1]-B1;nhat = nhat/norm(nhat,2);
-- Ref=eye(3) - 2*nhat*nhat';
-- Construct Rotation of xyz to TBN1
Rot=[T1,N1,B1];
circR=Rot*circR;
--translate circle center to r(1) + R1*N1
center = r(1) + R1*N1;
--center= [0;0;0];

for n=1:length(theta)
    circR(:,n)=circR(:,n)+center;
end
figure(H1)
plot3(circR(1,:),circR(2,:),circR(3,:),"c")
plot3(center(1),center(2),center(3),"g*")

end
}
