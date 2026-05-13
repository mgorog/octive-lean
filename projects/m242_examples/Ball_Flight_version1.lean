import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `Ball_Flight_version1.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
-- DOCUMENTATION: This script estimates positions (xnow, ynow), velocies (vxnow, vynow)
-- for an object fired from height y0=h0, x0=0,
-- at initial velocity v0 with elevation angle phi
-- under constant vertical acceleration a0.
-- The approximate maximum height and range is also estimated.
-- Author: B.Lundberg    Date: 01-27-2025


-- problem parameters
t0=0;a0=-9.8;
h0=10; -- initial time,acceleration, height
v0=100;
phi=30*pi/180;
v0x=v0*cos(phi);
vy0=v0*sin(phi); -- initial velocity
x0=0;
y0=h0; -- initial position

-- algorithm parameters
dt=0.01;MaxSteps=10^6;
format SHORTG
format compact
-- initialize algorithm variables
tnow=t0;
vxnow=vx0;
vynow=vy0;
xnow=x0;
ynow=y0;
disp("step, time, x, y, vx, vy")
disp([0,tnow,xnow,ynow,vxnow,vynow]) -- show initial state

-- Main Loop
for k=1:MaxSteps
    
    tprev=tnow;
    xprev=xnow;
yprev=ynow;
vxprev=vxnow;
vyprev=vynow; -- hold previous state
    vxnow=vxprev;
 vynow=vyprev+a0*dt; -- update velocities
    xnow=xprev+vxprev*dt;
 ynow=yprev+vyprev*dt;-- update position
    tnow = tnow+dt;
    
    if rem(k,20) == 0   -- show current state
        disp([k,tnow,xnow,ynow,vxnow,vynow])
    end  
    -- max height test and capture
    if vynow*vyprev <= 0
        kymax=k;
tmax=tnow;
ymax=ynow;
xmax=xnow;
vxmax=vxnow;vymax=vynow;
    end
    if ynow*yprev <= 0   -- ground impact test, capture, quit loop
        kend=k;
yend=yprev;
xend=xprev;
vxend=vxprev;
vyend=vyprev;
tend=tprev;
        break  -- causes jump out of the "for" loop
    end
    
end

-- Special Output
disp("Max: k, time, x, y, vx, vy")
disp([kymax,tmax,xmax,ymax,vxmax,vymax])

disp("Ground Impact: k, time, x, y, vx, vy")
disp([kend-1,tend,xend,yend,vxend,vyend])
}
