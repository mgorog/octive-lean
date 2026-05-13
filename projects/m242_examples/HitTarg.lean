import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `HitTarg.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {

function [Accg,Phig,RngE]=HitTarg(targetx, guess)
-- finds the control parameter
-- Accg  if global variable CASE = 1 
-- Phig  if global variable CASE = 2
-- that makes horizontal range = targetx
-- Returns value of the control parameter (Accg or Phig)
-- and the remaining "defect" actual range-targetx
-- SAMPLE COMMAND LINE CALLS AND RESULTS:
-- >>global CASE      >>CASE=2 % find initial angle phi to hit range = 200 
-- >>[Accg,Phig,RngE]=HitTarg(200, 67)  Accg=0,Phig=64.974,RngE=-4.456e-10 
-- >>[Accg,Phig,RngE]=HitTarg(200, 35)  Accg=0,Phig=22.164,RngE=-0.0019645
-- >>CASE=1; % find horizontal acceleration to hit target range = 200 
-- >>[Accg,Phig,RngE]=HitTarg(200, -0.1) Accg=-2.7804,Phig=0,RngE=-5.3461e-11

global CASE TARGETX;
TARGETX = targetx;
if CASE == 1 -- control variable is Accg
 -- control variable is Accx
 Accg=guess;
 Phig=0;
 [Accg,RngE] = fzero(@BFlgtRange_Ax,guess);  
else
 -- control variable is Phig
 Accg=0;
 Phig=guess;
 [Phig,RngE] = fzero(@BFlgtRange_phi0,guess);
end

end

-- -------------- SUBFUNCTIONS ------------------------

function RngeErr=BFlgtRange_Ax(Accx)
-- Subfunction for HitTarget
-- Ax = horizontal acceleration is the control variable
global TARGETX;
[Tmax,RVmax,Timp,RVimp]=BallFlight2(0,htranspose([0,10,50,0]), htranspose([Accx,-9.80665]),35,0.0001,1e6);
RngeErr= RVimp(1)-TARGETX;
end

function RngeErr=BFlgtRange_phi0(phi0)

global TARGETX;
[Tmax,RVmax,Timp,RVimp]=BallFlight2(0,htranspose([0,10,50,0]), htranspose([0,-9.80665]),phi0,0.0001,1e6);
RngeErr= RVimp(1)-TARGETX;
end
}
