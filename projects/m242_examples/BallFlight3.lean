import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `BallFlight3.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {

function [Tmax,RVmax,Timp,RVimp,T,Y,Ie]=BallFlight3(t0,RV0,Acc,phi0_deg,Cd_ball,r_ball,m_ball,prnt_flag)
-- DOCUMENTATION: This function estimates position and velocity 
-- RV = [xnow, ynow, vxnow, vynow]'
-- for an object fired from initial position and velocity
-- RV0 = [x0, y0, vx0, vy0]'
-- at initial elevation angle phi0_deg is present (nargin>3)
-- vx0 = vx0*cos(phi0_rad) and vy0 = vx0*sin(phi0_rad)
-- under constant vertical acceleration a0.
-- The approximate maximum height and range is also estimated.
-- SAMPLE CALL AND OUTPUT 
-- >>[Tmax,RVmax,Timp,RVimp,T,Y,Ie]=  --  BallFlight3(0,[0;0.01;60;0],[0,9.802],35,0.40,0.015,0.05,2);
-- Max y: time, x, y, vx, vy
--  2.4843   88.822  36.991    27.342  -7.5495e-15
-- Ground Impact y=0:  time, x, y, vx, vy
--  5.4419  153.65 -1.3101e-12 17.154  -23.09
-- Author: B.Lundberg  Date: v1:01-27-2025 Updates: v2:4-3-25, v3:4-14-25
-- Ref: https://file.scirp.org/pdf/WJM_2018062515520887.pdf

-- algorithm parameter defaults 
if nargin >7 && prnt_flag >0  
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
rho  = 1.062 ; -- air density in kg/m^3
visc_d =1.64; -- dynamic viscocity (1e-5 Ns/m^2)    
g = Accy; -- m/s^2 at h =1500;
h=y0;

-- Set up and solve the ODE
K_doverm=Cd_ball*rho*pi*r_ball^2/m_ball;
F_bflgt=@(t,y) [y(3:4);[Accx;-g], - K_doverm*y(3:4)*norm(y(3:4))];
TendEst=(vy0+sqrt(vy0^2+2*g*h))/g + t0;
Options1=odeset("RelTol",1e-8,"AbsTol",1e-5,"Events",@peak_impact_Events); 

[T,Y,Te,Ye,Ie] = ode45(F_bflgt,[t0:0.1:TendEst],htranspose([x0, y0, vx0, vy0]),Options1);    

-- Load Output Vars [Tmax,RVmax,Timp,RVimp]
Tmax=Te(1); RVmax=Ye(1,:);
Timp=Te(2); RVimp=Ye(2,:);

-- Optional Special Results Display to screen
if nargin>7 && prnt_flag >0 
-- Special Output
disp("Max: time, x, y, vx, vy")
disp([Tmax,RVmax])
disp("Ground Impact: time, x, y, vx, vy")
disp([Timp,RVimp])

--subplot(2,1,1)
plot(Y(:,1),Y(:,2))
v=axis;v=v+[-2,2,0,0];
axis equal
hold
 plot([v(1),v(2)],[0,0],"g")
axis(v)
xlabel("x (meters)")
 ylabel("y (meters)")
title("Golf Ball Flight")
hold_off()
--subplot(2,1,2)
--comet(Y(:,1),Y(:,2))
end

end

-- Subfunctions -- Events
  -- Max Height (zero vertical velocity)
  function [value,isterminal,direction] = peak_impact_Events(t,y)
  -- Peak Height
   value(1) = y(4);     -- Detect v_y(t) == 0 (peak height)
   isterminal(1) = 0;   -- Do not Stop the integration
   direction(1) = -1;   -- Negative direction only
   -- Ground Impact
   value(2) = y(2);     -- Detect y = 0 (impact with ground)
   isterminal(2) = 1;   -- Stop the integration if y(2) == 0
   direction(2) = -1;   -- Negative direction only
  end
}
