import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `BallFlight2.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
function [Tmax,RVmax,Timp,RVimp]=BallFlight2(t0,RV0,Acc,phi0_deg,dt,MaxSteps,prnt_flag)
-- DOCUMENTATION: This function estimates position and velocity 
-- RV = [xnow, ynow, vxnow, vynow]'
-- for an object fired from initial position and velocity
-- RV0 = [x0, y0, vx0, vy0]'
-- at initial elevation angle phi0_deg is present (nargin>3)
-- vx0 = vx0*cos(phi0_rad) and vy0 = vx0*sin(phi0_rad)
-- under constant vertical acceleration a0.
-- The approximate maximum height and range is also estimated.
-- SAMPLE CALL AND OUTPUT 
-- >>[Tmax,RVmax,Timp,RVimp]=Ball_Flight_v2(0,[0,10,50,0]',[0,-9.80665]',35,0.0001,1e5);
-- [Tmax,RVmax']   2.9245       119.78       51.936       40.958  -0.00072611
-- [Timp,RVimp']   6.179       253.08   0.00032024       40.958      -31.916
-- Author: B.Lundberg    Date: v1: 01-27-2025   Update to v2 4-3-25.

-- algorithm parameter defaults if nargin<5
dt=0.01; -- algorithm time step length
end
if nargin <6
    MaxSteps=1e6;
end
if nargin >6 && prnt_flag >0  
    format SHORTG
    format compact
end

-- Initial Position, Velocity, Acceleration
x0 = RV0(1);
y0 = RV0(2);
if nargin >3
    phi0_rad=pi*phi0_deg/180;
    vx0=RV0(3)*cos(phi0_rad);
    vy0=RV0(3)*sin(phi0_rad); -- initial velocity
else
    vx0 = RV0(3);
    vy0 = RV0(4);
end
if nargin<3
    Accy=-9.80665; -- standard figure for sea level (m/s^2)
                 -- at altitude H above sea level
                 -- gH = g0*(Re/(Re+H))^2, Re=Earth Mean Radius
    Accx=0;
else
    Accy=Acc(2); 
    Accx=Acc(1); 
end

-- initialize algorithm State variables
tnow=t0;
vxnow=vx0;
vynow=vy0;
xnow=x0;
ynow=y0;
tnow=t0;
vxnow=vx0;
vynow=vy0;
xnow=x0;
ynow=y0;
-- Optional Initial State Display
if nargin > 6 && prnt_flag >1    -- show current state
    disp("          step        time          x            y          vx           vy")
disp([0,tnow,xnow,ynow,vxnow,vynow]) -- show initial state
end

-- Main Loop
for k=1:MaxSteps
    
   -- Save previous state for comparisons
    tprev=tnow;   xprev=xnow;   yprev=ynow;
                  vxprev=vxnow; vyprev=vynow;
   -- Update Accelerations(assumed approx constant over time dt) for current step
    Acc_kx = Accx;  -- x Acceleration (assumed approx constant) for current step
    Acc_ky = Accy;  -- x Acceleration (assumed approx constant) for current step
  
   -- Update Velocities(assumed approx constant over time dt) for current step
    vxnow=vxprev+Acc_kx*dt; -- update velocities
    vynow=vyprev+Acc_ky*dt; -- update velocities
    
  -- Update Positions
    xnow=xprev+vxprev*dt;
    ynow=yprev+vyprev*dt;-- update position
    
    tnow = tnow+dt; -- advance time
    
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
    
    -- Optional Display of Step results
    if nargin>6 && prnt_flag >1 && rem(k,prnt_flag) == 0   -- show current state
        disp([k,tnow,xnow,ynow,vxnow,vynow])
    end 
    
end

-- Load Output Vars [Tmax,RVmax,Timp,RVimp]
Tmax=tmax;
 RVmax=htranspose([xmax, ymax, vxmax,vymax]);
Timp=tend;
 RVimp=htranspose([xend,yend,vxend,vyend]);

-- Optional Special Results Display to screen
if nargin>6 && prnt_flag >2 
-- Special Output
disp("Max: k, time, x, y, vx, vy")
disp([kymax,tmax,xmax,ymax,vxmax,vymax])
disp("Ground Impact: k, time, x, y, vx, vy")
disp([kend-1,tend,xend,yend,vxend,vyend])
end
}
