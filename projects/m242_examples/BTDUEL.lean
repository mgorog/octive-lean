import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `BTDUEL.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
function BTDUEL(Pilot,Gunnery,EPilot,EGunnery)
--Battletech 1 on 1 duel between two human players. Each pilot will be giving a shadow hawk. Other mechs can be loaded in 
--Enter in pilot skill, and Gunnery skill, numbers should be 1-6
--A regular Pilot and Gunnery skill is 4,4. 
--The lower the number the better the player is at that skill
--Player 1 is green color, while player 2 is blue color vectors
--To run the program enter in BTDUEL(4,4,4,4)
cir=0; --staring values
x=0;
MLOOP=0;
Round=1;
Continue=0;
EPOSX=0;
EPOSY=19.052;
PPOSX=6;
PPOSY=0;
EFACEX=0;
EFACEY=-0.866;
FACEX=0;
FACEY=0.866;
EDIR=4;
PDIR=1;
NUMWEAP=3;
ENUMWEAP=3;
GENHEAT=0;
EGENHEAT=0;
Pilot1=0;
Gunnery1=0;
EPilot1=0;
EGunnery1=0;
--%load Mech data
MECH=xlsread("mech.xlsx");
--armor values
EHead=MECH(1);Head=MECH(1);
ECT=MECH(2);CT=MECH(2);
ELT=MECH(3);LT=MECH(3);
ERT=MECH(4);RT=MECH(4);
ELA=MECH(5);LA=MECH(5);
ERA=MECH(5);RA=MECH(5);
ELL=MECH(6);LL=MECH(6);
ERL=MECH(7);RL=MECH(7);
ERCT=MECH(8);RCT=MECH(8);
ERLT=MECH(9);RLT=MECH(9);
ERRT=MECH(10);RRT=MECH(10);
--speed values
MRun=MECH(2,5);
MWalk=MECH(1,5);
--weapon data
Weapon1=MECH(2,2);
HeatWPN1=MECH(1,2);
SRangeWPN1=MECH(3,2);
MRangeWPN1=MECH(4,2);
LRangeWPN1=MECH(5,2);
Weapon2=MECH(2,3);
HeatWPN2=MECH(1,3);
SRangeWPN2=MECH(3,3);
MRangeWPN2=MECH(4,3);
LRangeWPN2=MECH(5,3);
Weapon3=MECH(2,4);
HeatWPN3=MECH(1,4);
SRangeWPN3=MECH(3,4);
MRangeWPN3=MECH(4,4);
LRangeWPN3=MECH(5,4);
--heat sinks
HeatSink=MECH(1,6);
--big loop for others
while Continue!= 1
    Round=Round+1;
--Roll to for intiative
ERoll=MULTIDICE(6,2); --Player 2 roll
PRoll=MULTIDICE(6,2); --Player 1 roll
while x!=1 --loop until results are not the same
    x=1;
if ERoll==PRoll
    ERoll=MULTIDICE(6,2); --Player 2 re-roll
    PRoll=MULTIDICE(6,2); --Player 1 re-roll
    x=0;
end
end
if ERoll>PRoll --set value for NPC Intiative 
    INTIATIVE=0; --Player 2 wins
else
    INTIATIVE=1; --Player 1 loses
end
--display postion
switch EDIR --%enemy facing vector
    case 1
        EFACEX=0;EFACEY=0.866;
    case 2
        EFACEX=-0.75;EFACEY=0.866;
    case 3
        EFACEX=-0.75;EFACEY=-0.866;
    case 4
        EFACEX=0;EFACEY=-0.866;
    case 5
        EFACEX=0.75;EFACEY=-0.866;
    case 6
        EFACEX=0.75;EFACEY=0.866;
end
switch PDIR  --% player facing vector
    case 1
        FACEX=0;FACEY=0.866;
    case 2
        FACEX=-0.75;FACEY=0.866;
    case 3
        FACEX=-0.75;FACEY=-0.866;
    case 4
        FACEX=0;FACEY=-0.866;
    case 5
        FACEX=0.75;FACEY=-0.866;
    case 6
        FACEX=0.75;FACEY=0.866;
end
quiver(EPOSX,EPOSY,EFACEX,EFACEY,"LineWidth",2),hold,quiver(PPOSX,PPOSY,FACEX,FACEY,"LineWidth",2),xlim([-1, 7]), ylim([-1, 21])
tt=0:60:360;
xz=cosd(tt);
yz=sind(tt);
n3=0;
k3=0;
nn=0;
m5=0;
kk=0;
while n3<13
plot(xz,yz+n3*1.732,"r")
n3=n3+1;
end
while k3<13
plot(xz+1.5,yz+k3*1.732-0.866,"r")
k3=k3+1;
end
while nn<13
plot(xz+3,yz+nn*1.732,"r")
nn=nn+1;   
end
while kk<13
plot(xz+4.5,yz+kk*1.732-0.866,"r")
kk=kk+1;
end
while m5<13
plot(xz+6,yz+m5*1.732,"r")
m5=m5+1;   
end
hold
--movement phase
if INTIATIVE==0 --if Player 2 Wins intiative
    disp("Player 1 Turn")
    
      
    PMOVE=input("Please enter a number (1) to walk or (2) to run ", "s");
     
   if PMOVE== 2
       
       PMOVE=MRun;
       PSPEEDPEN=2;
       GENHEAT=GENHEAT+2;
       MLOOP=1;
   else
      
       PMOVE=MWalk;
       PSPEEDPEN=1;
       GENHEAT=GENHEAT+1;
       MLOOP=1;
   
       
   end
   
   
TURNS=PMOVE;  
PPENMOVE=Pilot+PSPEEDPEN;
                               --ask if you like to make multiple direction
                               --changes and in which direction
                               --pilot check for each change and tell if fails
while TURNS!=0
     quiver(EPOSX,EPOSY,EFACEX,EFACEY,"LineWidth",2),hold,quiver(PPOSX,PPOSY,FACEX,FACEY,"LineWidth",2),xlim([-1, 7]), ylim([-1, 21])
tt=0:60:360;
xz=cosd(tt);
yz=sind(tt);
n3=0;
k3=0;
nn=0;
m5=0;
kk=0;
while n3<13
plot(xz,yz+n3*1.732,"r")
n3=n3+1;
end
while k3<13
plot(xz+1.5,yz+k3*1.732-0.866,"r")
k3=k3+1;
end
while nn<13
plot(xz+3,yz+nn*1.732,"r")
nn=nn+1;   
end
while kk<13
plot(xz+4.5,yz+kk*1.732-0.866,"r")
kk=kk+1;
end
while m5<13
plot(xz+6,yz+m5*1.732,"r")
m5=m5+1;   
end
hold    
     disp("you have "), disp(TURNS) ,disp("moves left.") 
Movement=input("Please select one of the following: 1.turn left 2 turn right 3 Go foward a space 4 Go back a space 5 Do not move ")
          switch Movement
              case 1
                  if PDIR ==6
                      PDIR=0;
                  end
                  
                  CHECK=MULTIDICE(6,2);  --roll for success/failure
                  if CHECK<PPENMOVE
                      PDIR=DICE(6);
                      disp("You have failed your pilot check")
                  end
                  
        
                  PDIR=PDIR+1;
                  TURNS=TURNS-1;
                  
              case 2
                  if PDIR ==1 
                      PDIR=7;
                  end
                  PDIR=PDIR-1;
                  TURNS=TURNS-1;
                  
                   CHECK=MULTIDICE(6,2);  --roll for success/failure
                  if CHECK<PPENMOVE
                      PDIR=DICE(6);
                      disp("You have failed your pilot check")
                  end
                  
              case 3
                 switch PDIR
                     case 1
                       PPOSY=PPOSY +1.732;
                       
                       if PPOSY >19.052
                          PPOSY=PPOSY-1.732;
                          disp("You can not go foward")
                          TURNS=TURNS+1
                       end
                       
                     case 2
                         PPOSX=PPOSX-1.5;
                         PPOSY=PPOSY+0.866;
                         
                         if PPOSY > 19.052| PPOSX< 0
                          PPOSX=PPOSX+1.5;
                          PPOSY=PPOSY-0.866;
                          disp("You can not go foward")
                          TURNS=TURNS+1
                         end
                       
                     case 3
                        PPOSX=PPOSX-1.5; 
                        PPOSY=PPOSY-0.866;
                        
                        if PPOSY < 0.866| PPOSX< 0
                          PPOSX=PPOSX+1.5;
                          PPOSY=PPOSY+0.866;
                          disp("You can not go foward")
                          TURNS=TURNS+1
                        end
                        
                     case 4
                         PPOSY=PPOSY -1.732;
                         
                         if PPOSY < 0
                          PPOSY=PPOSY+1.732;
                          disp("You can not go foward")
                          TURNS=TURNS+1
                         end
                       
                     case 5
                         PPOSX=PPOSX+1.5; 
                         PPOSY=PPOSY-0.866;
                         
                          if PPOSY < 0.866| PPOSX > 6
                          PPOSX=PPOSX-1.5;
                          PPOSY=PPOSY+0.866;
                          disp("You can not go foward")
                          TURNS=TURNS+1
                          end
                        
                     case 6
                         PPOSX=PPOSX+1.5; 
                         PPOSY=PPOSY+0.866;
                         
                          if PPOSY > 19.052| PPOSX > 6
                          PPOSX=PPOSX-1.5;
                          PPOSY=PPOSY-0.866;
                          disp("You can not go foward")
                          TURNS=TURNS+1
                        end
                 end
                 TURNS=TURNS-1;
                 CHECK=MULTIDICE(6,2);  --roll for success/failure
                  if CHECK<PPENMOVE
                      PDIR=DICE(6);
                      disp("You have failed your pilot check")
                  end
                  
              case 4
                 switch PDIR
                     case 1
                       PPOSY=PPOSY -1.732;
                       
                         if PPOSY <0.866
                          PPOSY=PPOSY+1.732;
                          disp("You can not go backward")
                          TURNS=TURNS+1;
                          end
                       
                     case 2
                         PPOSX=PPOSX+1.5;
                         PPOSY=PPOSY-0.866;
                         
                          if PPOSY <0.866| PPOSX>6
                          PPOSX=PPOSX-1.5;
                          PPOSY=PPOSY+0.866;
                          disp("You can not go backward")
                          TURNS=TURNS+1;
                          end
                         
                     case 3
                        PPOSX=PPOSX+1.5; 
                        PPOSY=PPOSY+0.866;
                        
                         if PPOSY > 19.052 | PPOSX> 6
                          PPOSX=PPOSX-1.5;
                          PPOSY=PPOSY-0.866;
                          disp("You can not go backward")
                          TURNS=TURNS+1;
                         end
                        
                     case 4
                         PPOSY=PPOSY +1.732;
                         
                          if PPOSY < 0
                          PPOSY=PPOSY-1.732;
                          disp("You can not go backwards")
                          TURNS=TURNS+1;
                          end
                         
                     case 5
                         PPOSX=PPOSX-1.5; 
                         PPOSY=PPOSY+0.866;
                         
                         if PPOSY > 19.052| PPOSX< 0
                          PPOSX=PPOSX+1.5;
                          PPOSY=PPOSY-0.866;
                          disp("You can not go backward")
                          TURNS=TURNS+1;
                         end
                         
                     case 6
                         PPOSX=PPOSX-1.5; 
                         PPOSY=PPOSY-0.866;
                         
                           if PPOSY < 0.866| PPOSX< 0
                          PPOSX=PPOSX+1.5;
                          PPOSY=PPOSY+0.866;
                          disp("You can not go backward")
                          TURNS=TURNS+1;
                           end
                 end
                 TURNS=TURNS-1;
                  CHECK=MULTIDICE(6,2);  --roll for success/failure
                  if CHECK<PPENMOVE
                      PDIR=DICE(6);
                      disp("You have failed your pilot check")
                  end
                  
              case 5
                  TURNS=0;
          end
    switch PDIR  --% player facing vector
    case 1
        FACEX=0;FACEY=0.866;
    case 2
        FACEX=-0.75;FACEY=0.866;
    case 3
        FACEX=-0.75;FACEY=-0.866;
    case 4
        FACEX=0;FACEY=-0.866;
    case 5
        FACEX=0.75;FACEY=-0.866;
    case 6
        FACEX=0.75;FACEY=0.866;
    end
    
end
  
  
  disp("Player 2 Turn")
  EMOVE=input("Please enter a number (1) to walk or (2) to run ", "s");
   
   if EMOVE ==2
      
       EMOVE=MRun;
       ESPEEDPEN=2;
       EGENHEAT=EGENHEAT+2;
       
   else
       EMOVE=MWalk;
       ESPEEDPEN=1;
       EGENHEAT=EGENHEAT+1;
       
     
   end
  ETURNS=EMOVE;  
EPENMOVE=EPilot+ESPEEDPEN;
                               --ask if you like to make multiple direction
                               --changes and in which direction
                               --pilot check for each change and tell if fails
while ETURNS!=0
     quiver(EPOSX,EPOSY,EFACEX,EFACEY,"LineWidth",2),hold,quiver(PPOSX,PPOSY,FACEX,FACEY,"LineWidth",2),xlim([-1, 7]), ylim([-1, 21])
tt=0:60:360;
xz=cosd(tt);
yz=sind(tt);
n3=0;
k3=0;
nn=0;
m5=0;
kk=0;
while n3<13
plot(xz,yz+n3*1.732,"r")
n3=n3+1;
end
while k3<13
plot(xz+1.5,yz+k3*1.732-0.866,"r")
k3=k3+1;
end
while nn<13
plot(xz+3,yz+nn*1.732,"r")
nn=nn+1;   
end
while kk<13
plot(xz+4.5,yz+kk*1.732-0.866,"r")
kk=kk+1;
end
while m5<13
plot(xz+6,yz+m5*1.732,"r")
m5=m5+1;   
end
hold
     disp("you have "),disp(ETURNS) ,disp("moves left.") 
Movement=input("Please select one of the following: 1.turn left 2 turn right 3 Go foward a space 4 Go back a space 5 Do not move ")
          switch Movement
              case 1
                  if EDIR ==6
                      EDIR=0;
                  end
                  
                  CHECK=MULTIDICE(6,2);  --roll for success/failure
                  if CHECK<EPENMOVE
                      EDIR=DICE(6);
                      disp("You have failed your pilot check")
                  end
                  
        
                  EDIR=EDIR+1;
                  ETURNS=ETURNS-1;
                  
              case 2
                  if EDIR ==1 
                      EDIR=7;
                  end
                  EDIR=EDIR-1;
                  ETURNS=ETURNS-1;
                  
                   CHECK=MULTIDICE(6,2);  --roll for success/failure
                  if CHECK<EPENMOVE
                      EDIR=DICE(6);
                      disp("You have failed your pilot check")
                  end
                  
                case 3
                 switch EDIR
                     case 1
                       EPOSY=EPOSY +1.732;
                       
                       if EPOSY >19.052
                          EPOSY=EPOSY-1.732;
                          disp("You can not go foward")
                          ETURNS=ETURNS+1;
                       end
                       
                     case 2
                         EPOSX=EPOSX-1.5;
                         EPOSY=EPOSY+0.866;
                         
                         if EPOSY > 19.052| EPOSX< 0
                          EPOSX=EPOSX+1.5;
                          EPOSY=EPOSY-0.866;
                          disp("You can not go foward")
                          ETURNS=ETURNS+1;
                         end
                       
                     case 3
                        EPOSX=EPOSX-1.5; 
                        EPOSY=EPOSY-0.866;
                        
                        if EPOSY < 0.866| EPOSX< 0
                          EPOSX=EPOSX+1.5;
                          EPOSY=EPOSY+0.866;
                          disp("You can not go foward")
                          ETURNS=ETURNS+1;
                        end
                        
                     case 4
                         EPOSY=EPOSY -1.732;
                         
                         if EPOSY < 0
                          EPOSY=EPOSY+1.732;
                          disp("You can not go foward")
                          ETURNS=ETURNS+1;
                         end
                       
                     case 5
                         EPOSX=EPOSX+1.5; 
                         EPOSY=EPOSY-0.866;
                         
                          if EPOSY < 0.866| EPOSX > 6
                          EPOSX=EPOSX-1.5;
                          EPOSY=EPOSY+0.866;
                          disp("You can not go foward")
                          ETURNS=ETURNS+1;
                          end
                        
                     case 6
                         EPOSX=EPOSX+1.5; 
                         EPOSY=EPOSY+0.866;
                         
                          if EPOSY > 19.052| EPOSX > 6
                          EPOSX=EPOSX-1.5;
                          EPOSY=EPOSY-0.866;
                          disp("You can not go foward")
                          ETURNS=ETURNS+1;
                          end
                 end
                 ETURNS=ETURNS-1;
                 CHECK=MULTIDICE(6,2);  --roll for success/failure
                  if CHECK<EPENMOVE
                      EDIR=DICE(6);
                      disp("You have failed your pilot check")
                  end
                  
              case 4
                 switch EDIR
                     case 1
                       EPOSY=EPOSY -1.732;
                       
                         if EPOSY <0.866
                          EPOSY=EPOSY+1.732;
                          disp("You can not go backward")
                          ETURNS=ETURNS+1;
                       end
                       
                     case 2
                         EPOSX=EPOSX+1.5;
                         EPOSY=EPOSY-0.866;
                         
                          if EPOSY <0.866| EPOSX>6
                          EPOSX=EPOSX-1.5;
                          EPOSY=EPOSY+0.866;
                          disp("You can not go backward")
                          ETURNS=ETURNS+1;
                          end
                         
                     case 3
                        EPOSX=EPOSX+1.5; 
                        EPOSY=EPOSY+0.866;
                        
                         if EPOSY > 19.052 | EPOSX> 6
                          EPOSX=EPOSX-1.5;
                          EPOSY=EPOSY-0.866;
                          disp("You can not go backward")
                          ETURNS=ETURNS+1;
                         end
                        
                     case 4
                         EPOSY=EPOSY +1.732;
                         
                          if EPOSY < 0
                          EPOSY=EPOSY-1.732;
                          disp("You can not go backwards")
                          ETURNS=ETURNS+1;
                          end
                         
                     case 5
                         EPOSX=EPOSX-1.5; 
                         EPOSY=EPOSY+0.866;
                         
                         if EPOSY > 19.052| EPOSX< 0
                          EPOSX=EPOSX+1.5;
                          EPOSY=EPOSY-0.866;
                          disp("You can not go backward")
                          ETURNS=ETURNS+1;
                         end
                         
                     case 6
                         EPOSX=EPOSX-1.5; 
                         EPOSY=EPOSY-0.866;
                         
                           if EPOSY < 0.866| EPOSX< 0
                          EPOSX=EPOSX+1.5;
                          EPOSY=EPOSY+0.866;
                          disp("You can not go backward")
                          ETURNS=ETURNS+1;
                           end
                 end
                 ETURNS=ETURNS-1;
                  CHECK=MULTIDICE(6,2);  --roll for success/failure
                  if CHECK<EPENMOVE
                      EDIR=DICE(6);
                      disp("You have failed your pilot check")
                  end
              case 5
                  ETURNS=0;
          end
          switch EDIR --%enemy facing vector
    case 1
        EFACEX=0;EFACEY=0.866;
    case 2
        EFACEX=-0.75;EFACEY=0.866;
    case 3
        EFACEX=-0.75;EFACEY=-0.866;
    case 4
        EFACEX=0;EFACEY=-0.866;
    case 5
        EFACEX=0.75;EFACEY=-0.866;
    case 6
        EFACEX=0.75;EFACEY=0.866;
          end
end
else
    disp("Player 2 Turn")
   
    EMOVE=input("Please enter a number (1) to walk or (2) to run ", "s");
     while MLOOP!=1
        MLOOP=1;
   if EMOVE==2
       
       EMOVE=MRun;
       ESPEEDPEN=2;
       EGENHEAT=EGENHEAT+2;
      
       
       else
       EMOVE=MWalk;
       ESPEEDPEN=1;
       EGENHEAT=EGENHEAT+1;
      
        end
    end
  ETURNS=EMOVE;  
EPENMOVE=EPilot+ESPEEDPEN;
                               --ask if you like to make multiple direction
                               --changes and in which direction
                               --pilot check for each change and tell if fails
while ETURNS!=0
disp("you have "),disp(ETURNS),disp("moves left.") 
quiver(EPOSX,EPOSY,EFACEX,EFACEY,"LineWidth",2),hold,quiver(PPOSX,PPOSY,FACEX,FACEY,"LineWidth",2),xlim([-1, 7]), ylim([-1, 21])
tt=0:60:360;
xz=cosd(tt);
yz=sind(tt);
n3=0;
k3=0;
nn=0;
m5=0;
kk=0;
while n3<13
plot(xz,yz+n3*1.732,"r")
n3=n3+1;
end
while k3<13
plot(xz+1.5,yz+k3*1.732-0.866,"r")
k3=k3+1;
end
while nn<13
plot(xz+3,yz+nn*1.732,"r")
nn=nn+1;   
end
while kk<13
plot(xz+4.5,yz+kk*1.732-0.866,"r")
kk=kk+1;
end
while m5<13
plot(xz+6,yz+m5*1.732,"r")
m5=m5+1;   
end
hold
Movement=input("Please select one of the following:1.turn left 2 turn right 3 Go foward a space 4 Go back a space 5 Do not move ");
          switch Movement
              case 1
                  if EDIR ==6
                      EDIR=0;
                  end
                  
                  CHECK=MULTIDICE(6,2);  --roll for success/failure
                  if CHECK<EPENMOVE
                      EDIR=DICE(6);
                      disp("You have failed your pilot check")
                  end
                  
        
                  EDIR=EDIR+1;
                  ETURNS=ETURNS-1;
                  
              case 2
                  if EDIR ==1 
                      EDIR=7;
                  end
                  EDIR=EDIR-1;
                  ETURNS=ETURNS-1;
                  
                   CHECK=MULTIDICE(6,2);  --roll for success/failure
                  if CHECK<EPENMOVE
                      EDIR=DICE(6);
                      disp("You have failed your pilot check")
                  end
                  
                case 3
                 switch EDIR
                     case 1
                       EPOSY=EPOSY +1.732;
                       
                       if EPOSY >19.052
                          EPOSY=EPOSY-1.732;
                          disp("You can not go foward")
                          ETURNS=ETURNS+1;
                       end
                       
                     case 2
                         EPOSX=EPOSX-1.5;
                         EPOSY=EPOSY+0.866;
                         
                         if EPOSY > 19.052| EPOSX< 0
                          EPOSX=EPOSX+1.5;
                          EPOSY=EPOSY-0.866;
                          disp("You can not go foward")
                          ETURNS=ETURNS+1;
                         end
                       
                     case 3
                        EPOSX=EPOSX-1.5; 
                        EPOSY=EPOSY-0.866;
                        
                        if EPOSY < 0.866| EPOSX< 0
                          EPOSX=EPOSX+1.5;
                          EPOSY=EPOSY+0.866;
                          disp("You can not go foward")
                          ETURNS=ETURNS+1;
                        end
                        
                     case 4
                         EPOSY=EPOSY -1.732;
                         
                         if EPOSY < 0
                          EPOSY=EPOSY+1.732;
                          disp("You can not go foward")
                          ETURNS=ETURNS+1;
                         end
                       
                     case 5
                         EPOSX=EPOSX+1.5; 
                         EPOSY=EPOSY-0.866;
                         
                          if EPOSY < 0.866| EPOSX > 6
                          EPOSX=EPOSX-1.5;
                          EPOSY=EPOSY+0.866;
                          disp("You can not go foward")
                          ETURNS=ETURNS+1;
                          end
                        
                     case 6
                         EPOSX=EPOSX+1.5; 
                         EPOSY=EPOSY+0.866;
                         
                          if EPOSY > 19.052| EPOSX > 6
                          EPOSX=EPOSX-1.5;
                          EPOSY=EPOSY-0.866;
                          disp("You can not go foward")
                          ETURNS=ETURNS+1;
                          end
                 end
                 ETURNS=ETURNS-1;
                 CHECK=MULTIDICE(6,2);  --roll for success/failure
                  if CHECK<EPENMOVE
                      EDIR=DICE(6);
                      disp("You have failed your pilot check")
                  end
                  
              case 4
                 switch EDIR
                     case 1
                       EPOSY=EPOSY -1.732;
                       
                         if EPOSY <0.866
                          EPOSY=EPOSY+1.732;
                          disp("You can not go backward")
                          ETURNS=ETURNS+1;
                         end
                       
                     case 2
                         EPOSX=EPOSX+1.5;
                         EPOSY=EPOSY-0.866;
                         
                          if EPOSY <0.866| EPOSX>6
                          EPOSX=EPOSX-1.5;
                          EPOSY=EPOSY+0.866;
                          disp("You can not go backward")
                          ETURNS=ETURNS+1;
                          end
                         
                     case 3
                        EPOSX=EPOSX+1.5; 
                        EPOSY=EPOSY+0.866;
                        
                         if EPOSY > 19.052 | EPOSX> 6
                          EPOSX=EPOSX-1.5;
                          EPOSY=EPOSY-0.866;
                          disp("You can not go backward")
                          ETURNS=ETURNS+1;
                         end
                        
                     case 4
                         EPOSY=EPOSY +1.732;
                         
                          if EPOSY < 0
                          EPOSY=EPOSY-1.732;
                          disp("You can not go backwards")
                          ETURNS=ETURNS+1;
                          end
                         
                     case 5
                         EPOSX=EPOSX-1.5; 
                         EPOSY=EPOSY+0.866;
                         
                         if EPOSY > 19.052| EPOSX< 0
                          EPOSX=EPOSX+1.5;
                          EPOSY=EPOSY-0.866;
                          disp("You can not go backward")
                          ETURNS=ETURNS+1;
                         end
                         
                     case 6
                         EPOSX=EPOSX-1.5; 
                         EPOSY=EPOSY-0.866;
                         
                           if EPOSY < 0.866| EPOSX< 0
                          EPOSX=EPOSX+1.5;
                          EPOSY=EPOSY+0.866;
                          disp("You can not go backward")
                          ETURNS=ETURNS+1;
                           end
                 end
                 ETURNS=ETURNS-1;
                  CHECK=MULTIDICE(6,2);  --roll for success/failure
                  if CHECK<EPENMOVE
                      EDIR=DICE(6);
                      disp("You have failed your pilot check")
                  end
              case 5
                  ETURNS=0;
          end
          switch EDIR --%enemy facing vector
    case 1
        EFACEX=0;EFACEY=0.866;
    case 2
        EFACEX=-0.75;EFACEY=0.866;
    case 3
        EFACEX=-0.75;EFACEY=-0.866;
    case 4
        EFACEX=0;EFACEY=-0.866;
    case 5
        EFACEX=0.75;EFACEY=-0.866;
    case 6
        EFACEX=0.75;EFACEY=0.866;
          end
end
  disp("Player 1 Turn")
   PMOVE=input("Please enter a number (1) to walk or (2) to run ", "s");
  
   if PMOVE==2
       
       PMOVE=MRun;
       PSPEEDPEN=2;
       GENHEAT=GENHEAT+2;
       
   else
       PMOVE=MWalk;
       PSPEEDPEN=1;
       GENHEAT=GENHEAT+1;
         
   end
  TURNS=PMOVE;  
PPENMOVE=Pilot+PSPEEDPEN;
                               --ask if you like to make multiple direction
                               --changes and in which direction
                               --pilot check for each change and tell if fails
while TURNS!=0
disp("you have "), disp(TURNS) ,disp("moves left.")
quiver(EPOSX,EPOSY,EFACEX,EFACEY,"LineWidth",2),hold,quiver(PPOSX,PPOSY,FACEX,FACEY,"LineWidth",2),xlim([-1, 7]), ylim([-1, 21])
tt=0:60:360;
xz=cosd(tt);
yz=sind(tt);
n3=0;
k3=0;
nn=0;
m5=0;
kk=0;
while n3<13
plot(xz,yz+n3*1.732,"r")
n3=n3+1;
end
while k3<13
plot(xz+1.5,yz+k3*1.732-0.866,"r")
k3=k3+1;
end
while nn<13
plot(xz+3,yz+nn*1.732,"r")
nn=nn+1;   
end
while kk<13
plot(xz+4.5,yz+kk*1.732-0.866,"r")
kk=kk+1;
end
while m5<13
plot(xz+6,yz+m5*1.732,"r")
m5=m5+1;   
end
hold
Movement=input("Please select one of the following: 1.turn left 2 turn right 3 Go foward a space 4 Go back a space 5 Do not move ");
          switch Movement
              case 1
                  if PDIR ==6
                      PDIR=0;
                  end
                  
                  CHECK=MULTIDICE(6,2);  --roll for success/failure
                  if CHECK<PPENMOVE
                      PDIR=DICE(6);
                      disp("You have failed your pilot check")
                  end
                  
        
                  PDIR=PDIR+1;
                  TURNS=TURNS-1;
                  
              case 2
                  if PDIR ==1 
                      PDIR=7;
                  end
                  PDIR=PDIR-1;
                  TURNS=TURNS-1;
                  
                   CHECK=MULTIDICE(6,2);  --roll for success/failure
                  if CHECK<PPENMOVE
                      PDIR=DICE(6);
                      disp("You have failed your pilot check")
                  end
                  
              case 3
                 switch PDIR
                     case 1
                       PPOSY=PPOSY +1.732;
                       
                       if PPOSY >19.052
                          PPOSY=PPOSY-1.732;
                          disp("You can not go foward")
                          TURNS=TURNS+1
                       end
                       
                     case 2
                         PPOSX=PPOSX-1.5;
                         PPOSY=PPOSY+0.866;
                         
                         if PPOSY > 19.052| PPOSX< 0
                          PPOSX=PPOSX+1.5;
                          PPOSY=PPOSY-0.866;
                          disp("You can not go foward")
                          TURNS=TURNS+1;
                         end
                       
                     case 3
                        PPOSX=PPOSX-1.5; 
                        PPOSY=PPOSY-0.866;
                        
                        if PPOSY < 0.866| PPOSX< 0
                          PPOSX=PPOSX+1.5;
                          PPOSY=PPOSY+0.866;
                          disp("You can not go foward")
                          TURNS=TURNS+1;
                        end
                        
                     case 4
                         PPOSY=PPOSY -1.732;
                         
                         if PPOSY < 0
                          PPOSY=PPOSY+1.732;
                          disp("You can not go foward")
                          TURNS=TURNS+1;
                         end
                       
                     case 5
                         PPOSX=PPOSX+1.5; 
                         PPOSY=PPOSY-0.866;
                         
                          if PPOSY < 0.866| PPOSX > 6
                          PPOSX=PPOSX-1.5;
                          PPOSY=PPOSY+0.866;
                          disp("You can not go foward")
                          TURNS=TURNS+1;
                          end
                        
                     case 6
                         PPOSX=PPOSX+1.5; 
                         PPOSY=PPOSY+0.866;
                         
                          if PPOSY > 19.052| PPOSX > 6
                          PPOSX=PPOSX-1.5;
                          PPOSY=PPOSY-0.866;
                          disp("You can not go foward")
                          TURNS=TURNS+1;
                          end
                 end
                 TURNS=TURNS-1;
                 CHECK=MULTIDICE(6,2);  --roll for success/failure
                  if CHECK<PPENMOVE
                      PDIR=DICE(6);
                      disp("You have failed your pilot check")
                  end
                  
              case 4
                 switch PDIR
                     case 1
                       PPOSY=PPOSY -1.732;
                       
                         if PPOSY <0.866
                          PPOSY=PPOSY+1.732;
                          disp("You can not go backward")
                          TURNS=TURNS+1;
                         end
                       
                     case 2
                         PPOSX=PPOSX+1.5;
                         PPOSY=PPOSY-0.866;
                         
                          if PPOSY <0.866| PPOSX>6
                          PPOSX=PPOSX-1.5;
                          PPOSY=PPOSY+0.866;
                          disp("You can not go backward")
                          TURNS=TURNS+1;
                          end
                         
                     case 3
                        PPOSX=PPOSX+1.5; 
                        PPOSY=PPOSY+0.866;
                        
                         if PPOSY > 19.052 | PPOSX> 6
                          PPOSX=PPOSX-1.5;
                          PPOSY=PPOSY-0.866;
                          disp("You can not go backward")
                          TURNS=TURNS+1;
                         end
                        
                     case 4
                         PPOSY=PPOSY +1.732;
                         
                          if PPOSY < 0
                          PPOSY=PPOSY-1.732;
                          disp("You can not go backwards")
                          TURNS=TURNS+1;
                          end
                         
                     case 5
                         PPOSX=PPOSX-1.5; 
                         PPOSY=PPOSY+0.866;
                         
                         if PPOSY > 19.052| PPOSX< 0
                          PPOSX=PPOSX+1.5;
                          PPOSY=PPOSY-0.866;
                          disp("You can not go backward")
                          TURNS=TURNS+1;
                         end
                         
                     case 6
                         PPOSX=PPOSX-1.5; 
                         PPOSY=PPOSY-0.866;
                         
                         if PPOSY < 0.866| PPOSX< 0
                          PPOSX=PPOSX+1.5;
                          PPOSY=PPOSY+0.866;
                          disp("You can not go backward")
                          TURNS=TURNS+1
                        end
                 end
                 TURNS=TURNS-1;
                  CHECK=MULTIDICE(6,2);  --roll for success/failure
                  if CHECK<PPENMOVE
                      PDIR=DICE(6);
                      disp("You have failed your pilot check")
                  end
                  
              case 5
                  TURNS=0;
          end
    switch PDIR  --% player facing vector
    case 1
        FACEX=0;FACEY=0.866;
    case 2
        FACEX=-0.75;FACEY=0.866;
    case 3
        FACEX=-0.75;FACEY=-0.866;
    case 4
        FACEX=0;FACEY=-0.866;
    case 5
        FACEX=0.75;FACEY=-0.866;
    case 6
        FACEX=0.75;FACEY=0.866;
    end
    
end
  end
          
           --display postion change
quiver(EPOSX,EPOSY,EFACEX,EFACEY,"LineWidth",2),hold,quiver(PPOSX,PPOSY,FACEX,FACEY,"LineWidth",2),xlim([-1, 7]), ylim([-1, 21])
tt=0:60:360;
xz=cosd(tt);
yz=sind(tt);
n3=0;
k3=0;
nn=0;
m5=0;
kk=0;
while n3<13
plot(xz,yz+n3*1.732,"r")
n3=n3+1;
end
while k3<13
plot(xz+1.5,yz+k3*1.732-0.866,"r")
k3=k3+1;
end
while nn<13
plot(xz+3,yz+nn*1.732,"r")
nn=nn+1;   
end
while kk<13
plot(xz+4.5,yz+kk*1.732-0.866,"r")
kk=kk+1;
end
while m5<13
plot(xz+6,yz+m5*1.732,"r")
m5=m5+1;   
end
hold
--attack Phase
--relative location
switch PDIR
    case 1
        if PPOSY>EPOSY
            NUMWEAP=0;
        end
    case 2
        if PPOSX>EPOSX
           NUMWEAP=0; 
        end
    case 3
        if PPOSX>EPOSX
           NUMWEAP=0; 
        end
    case 4
        if PPOSY<EPOSY
            NUMWEAP=0;
        end
    case 5
        if PPOSX<EPOSX
           NUMWEAP=0; 
        end
    case 6
        if PPOSX>EPOSX
           NUMWEAP=0; 
        end
end        
switch EDIR
    case 1
        if PPOSY<EPOSY
            ENUMWEAP=0;
        end
    case 2
        if PPOSX<EPOSX
           ENUMWEAP=0; 
        end
    case 3
        if PPOSX<EPOSX
           ENUMWEAP=0; 
        end
    case 4
        if PPOSY<EPOSY
           ENUMWEAP=0;
        end
    case 5
        if PPOSX<EPOSX
           ENUMWEAP=0; 
        end
    case 6
        if PPOSX<EPOSX
           ENUMWEAP=0; 
        end
end  
if INTIATIVE==0
    disp("Player 1 TURN")
    disp("You have "),disp(NUMWEAP),disp("avialible to fire. Do you wish to fire?")
    switch NUMWEAP
        case 3 --%all weapons intacted
            attack=input("Please select a number to fire aweapon. 1. Fires medium Laser. 2. Fires Auto cannon. 3. Fires large laser. 4 Alpha strike (fires all). 5.Do not fire : ","s");
            
            switch attack
                case 1 --%case 1 selection
                    
                    DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                    
                   if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    
                       
             
                    ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon1;
end
GENHEAT=GENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      GENHEAT=GENHEAT+HeatWPN1;
                    end
                    
                
                case 2 --%case 1 selection
                        DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                    
                    if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2|| ADIST < MRangeWPN2 &&ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2|| ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                    
                    ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon2;
end
GENHEAT=HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      GENHEAT=HeatWPN2;
                    end
                    
                case 3 --%case 1 selection
                     DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                    
                    if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                    
                    ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon3;
end
GENHEAT=HeatWPN3;
                    else
                        disp("Large Laser missed")
                      GENHEAT=HeatWPN3;
                    end
                    
                case 4 --%case 1 overall selection
                     DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                     if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    
                    ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon1;
end
GENHEAT=GENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      GENHEAT=GENHEAT+HeatWPN1;
                    end
                     DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                     if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                
                     ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon2;
end
GENHEAT=GENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      GENHEAT=GENHEAT+HeatWPN2;
                    end
                     DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                     if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                
                    ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon3;
end
GENHEAT=GENHEAT+HeatWPN3;
                    else
                      disp("Large Laser missed")
                      GENHEAT=GENHEAT+HeatWPN3;
                    end
                case 5
                    APHASE=3;
            end
            
        case 2  --%1 weapon destroyed
            if RA<=0
                attack=input("Please select a weapon to fire. 1. Fires Auto cannon. 2. Fires small laser. 3 Alpha strike (fires all). 4.Do not fire : ")
   switch attack
       case 1
            DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                  
                  if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                     ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon2;
end
GENHEAT=HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      GENHEAT=HeatWPN2;
                    end
       case 2
            DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                    if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                          ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon3;
end
GENHEAT=GENHEAT+HeatWPN3;
                    else
                      disp("Large Laser missed")
                      GENHEAT=GENHEAT+HeatWPN3;
                    end
                    
       case 3    
            DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                      if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                    
                     ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon2;
end
GENHEAT=GENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      GENHEAT=GENHEAT+HeatWPN2;
                    end
                     DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                     if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                
                    ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon3;
end
GENHEAT=GENHEAT+HeatWPN3;
                    else
                      disp("large Laser missed")
                      GENHEAT=GENHEAT+HeatWPN3;
                    end
       case 4
           APHASE=3;
            end
   end
        if LT <=0
            attack=input("Please select a weapon to fire. 1. Fires medium laser 2. Fires large laser. 3 Alpha strike (fires all). 4. Do not fire: ")
            switch attack
              case 1
                   DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                   if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon1;
end
GENHEAT=GENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      GENHEAT=GENHEAT+HeatWPN1;
                    end
                    
              case 2
                   DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                   if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon3;
end
GENHEAT=GENHEAT+HeatWPN3;
                    else
                      disp("large Laser missed")
                      GENHEAT=GENHEAT+HeatWPN3;
                    end
              case 3
                   DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                   if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                      ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon1;
end
GENHEAT=GENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      GENHEAT=GENHEAT+HeatWPN1;
                    end
                     DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                     if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon3;
end
GENHEAT=GENHEAT+HeatWPN3;
                    else
                      disp("large Laser missed")
                      GENHEAT=GENHEAT+HeatWPN3;
                    end
              case 4
                  APHASE=3;
                  
        end
        end
            if LA<=0
                attack=input("Please select a weapon to fire. 1. Fires medium laser 2.Fires Auto Cannon. 3 Alpha strike (fires all). 4. Do Not Fire: ") 
                 DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
           switch attack
               
               case 1
                    if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                       ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon1;
end
GENHEAT=GENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      GENHEAT=GENHEAT+HeatWPN1;
                    end
                    
               case 2
                    if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                     ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon2;
end
GENHEAT=GENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      GENHEAT=GENHEAT+HeatWPN2;
                    end
               case 3
                    if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon1;
end
                    else
                        disp("Medium laser missed")
                      GENHEAT=GENHEAT+HeatWPN1;
                    end
                     if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon2;
end
       GENHEAT=GENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      GENHEAT=GENHEAT+HeatWPN2;
                    end
               case 4
                   APHASE=3;
           end
            end
        case 1
            if LA<=0 & LT<=0
               attack=input("Please select a weapon to fire. 1 Fires medium laser 2. Do not fire")
                DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
               switch attack
                   case 1
                    if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon1;
end
GENHEAT=GENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      GENHEAT=GENHEAT+HeatWPN1;
                    end 
                   case 2
                       APHASE=3;
               end
              
            if RA<=0&LA<=0
                 DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                attack=input("Please select a weapon to fire. 1 Fires Auto Cannon 2. Do not fire")
                switch attack
                    case 1
                         if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon2;
end
GENHEAT=GENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      GENHEAT=GENHEAT+HeatWPN2;
                    end  
                
                    case 2
                        APHASE=3;
                end
                
            end
            if RA<=0 & LA<=0
                 DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
              attack=input("Please select a weapon to fire. 1 Large laser 2. Do not fire")
              switch attack
                  case 1
                    if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                      
                    ATTCHECK=Gunnery+ESPEEDPEN+PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon3;
end
GENHEAT=GENHEAT+HeatWPN3;
                    else
                      disp("large Laser missed")
                      GENHEAT=GENHEAT+HeatWPN3;
                    end
                  case 2
                       APHASE=3;
              end
              
            end
            end
        case 0
            disp("All off your weapons have been destroyed!")
    end
--% Player 2 attacks
disp("Player 2 TURN")
  disp("You have "),disp(ENUMWEAP), disp("avialible to fire. Do you wish to fire?")
    switch ENUMWEAP
        case 3 --%all weapons intacted
            attack=input("Please select a number to fire aweapon. 1. Fires medium Laser. 2. Fires Auto cannon. 3. Fires large laser. 4 Alpha strike (fires all). 5.Do not fire : ")
            
            switch attack
                case 1 --%case 1 selection
                    
                    DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                    
                   if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    
                       
             
                    ATTCHECK=EGunnery-PSPEEDPEN+ESPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon1;
end
EGENHEAT=EGENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN1;
                    end
                    
                
                case 2 --%case 1 selection
                        DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                    
                    if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2|| ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2|| ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                    
                    ATTCHECK=EGunnery-PSPEEDPEN+ESPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon2;
end
EGENHEAT=EGENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      EGENHEAT=EGENHEAT+HeatWPN2;
                    end
                    
                case 3 --%case 1 selection
                    DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                    if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                    
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon3;
end
EGENHEAT=EGENHEAT+HeatWPN3;
                    else
                        disp("Large Laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN3;
                    end
                    
                case 4 --%case 1 overall selection
                    
                    DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                     if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    
                    
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
       Head=Head-Weapon1;
end
EGENHEAT=EGENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN1;
                    end
                    DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                     if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                
                     ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon2;
end
EGENHEAT=EGENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      EGENHEAT=EGENHEAT+HeatWPN2;
                    end
                    DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                     if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon3;
end
EGENHEAT=EGENHEAT+HeatWPN3;
                    else
                      disp("Large Laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN3;
                    end
                case 5
                    APHASE=3;
            end
            
        case 2  --%1 weapon destroyed
            if RA<=0
                attack=input("Please select a weapon to fire. 1. Fires Auto cannon. 2. Fires small laser. 3 Alpha strike (fires all). 4.Do not fire : ")
   switch attack
       case 1
                  DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                  if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                     ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon2;
end
EGENHEAT=EGENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      EGENHEAT=EGENHEAT+HeatWPN2;
                    end
       case 2
                      DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                    if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                          ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon3;
end
EGENHEAT=EGENHEAT+HeatWPN3;
                    else
                      disp("Large Laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN3;
                    end
                    
       case 3    
                       DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                      if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                    
                     ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon2;
end
EGENHEAT=EGENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      EGENHEAT=EGENHEAT+HeatWPN2;
                    end
                    DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                     if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon3;
end
EGENHEAT=EGENHEAT+HeatWPN3;
                    else
                      disp("large Laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN3;
                    end
       case 4
           APHASE=3;
            end
   end
        if LT <=0
            attack=input("Please select a weapon to fire. 1. Fires medium laser 2. Fires large laser. 3 Alpha strike (fires all). 4. Do not fire: ")
          switch attack
              case 1
                  DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                   if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon1;
end
EGENHEAT=EGENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN1;
                    end
                    
              case 2
                  DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                   if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon3;
end
EGENHEAT=EGENHEAT+HeatWPN3;
                    else
                      disp("large Laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN3;
                    end
              case 3
                  DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                   if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                      ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon1;
end
EGENHEAT=EGENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN1;
                    end
                    DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                     if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon3;
end
EGENHEAT=EGENHEAT+HeatWPN3;
                    else
                      disp("large Laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN3;
                    end
              case 4
                  APHASE=3;
                  
        end
        end
            if LA<=0
                attack=input("Please select a weapon to fire. 1. Fires medium laser 2.Fires Auto Cannon. 3 Alpha strike (fires all). 4. Do Not Fire: ") 
           switch attack
               
               case 1
                       DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                    if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                       ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon1;
end
EGENHEAT=EGENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN1;
                    end
                    
               case 2
                       DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                    if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                     ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon2;
end
EGENHEAT=EGENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      EGENHEAT=EGENHEAT+HeatWPN2;
                    end
               case 3
                       DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                    if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon1;
end
EGENHEAT=EGENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN1;
                    end
                       DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                     if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon2;
end
       EGENHEAT=EGENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      EGENHEAT=EGENHEAT+HeatWPN2;
                    end
               case 4
                   APHASE=3;
           end
            end
        case 1
            if LA<=0 & LT<=0
               attack=input("Please select a weapon to fire. 1 Fires medium laser 2. Do not fire")
               DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                ADIST=DIST/1.732;
               switch attack
                   case 1
                    if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 & ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 & ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon1;
end
EGENHEAT=EGENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN1;
                    end 
                   case 2
                       APHASE=3;
               end
              
            if RA<=0&LA<=0
                attack=input("Please select a weapon to fire. 1 Fires Auto Cannon 2. Do not fire")
                       DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                switch attack
                    
                    case 1
                         if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon2;
end
EGENHEAT=EGENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      EGENHEAT=EGENHEAT+HeatWPN2;
                    end  
                
                    case 2
                        APHASE=3;
                end
                
            end
            if RA<=0 & LA<=0
              attack=input("Please select a weapon to fire. 1 Large laser 2. Do not fire")
              switch attack
                  case 1
                    if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                      
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon3;
end
EGENHEAT=EGENHEAT+HeatWPN3;
                    else
                      disp("large Laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN3;
                    end
                  case 2
                       APHASE=3;
              end
              
            end
            end
        case 0
            disp("All off your weapons have been destroyed!")
    end
    
else
    disp("Player 2 TURN")
     disp("You have "),disp(ENUMWEAP), disp(" Do you wish to fire?")
    switch ENUMWEAP
        case 3 --%all weapons intacted
            attack=input("Please select a number to fire aweapon. 1. Fires medium Laser. 2. Fires Auto cannon. 3. Fires large laser. 4 Alpha strike (fires all). 5.Do not fire : ")
             DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
            switch attack
                case 1 --%case 1 selection
                    
                    DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                    
                   if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    
                       
             
                    ATTCHECK=EGunnery-PSPEEDPEN+ESPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon1;
end
EGENHEAT=EGENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN1;
                    end
                    
                
                case 2 --%case 1 selection
                        DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                    
                    if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2|| ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2|| ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                    
                    ATTCHECK=EGunnery-PSPEEDPEN+ESPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon2;
end
EGENHEAT=EGENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      EGENHEAT=EGENHEAT+HeatWPN2;
                    end
                    
                case 3 --%case 1 selection
                       DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                    if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                    
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon3;
end
EGENHEAT=EGENHEAT+HeatWPN3;
                    else
                        disp("Large Laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN3;
                    end
                    
                case 4 --%case 1 overall selection
                     DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                       ADIST=DIST/1.732;
                     if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
       Head=Head-Weapon1;
end
EGENHEAT=EGENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN1;
                    end
                     if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                
                     ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon2;
end
EGENHEAT=EGENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      EGENHEAT=EGENHEAT+HeatWPN2;
                    end
                     if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon3;
end
EGENHEAT=EGENHEAT+HeatWPN3;
                    else
                      disp("Large Laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN3;
                    end
                case 5
                    APHASE=3;
            end
            
        case 2  --%1 weapon destroyed
            if RA<=0
                attack=input("Please select a weapon to fire. 1. Fires Auto cannon. 2. Fires small laser. 3 Alpha strike (fires all). 4.Do not fire : ")
   switch attack
       case 1
                  
                  if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                     ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon2;
end
EGENHEAT=EGENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      EGENHEAT=EGENHEAT+HeatWPN2;
                    end
       case 2
                    if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                          ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon3;
end
EGENHEAT=EGENHEAT+HeatWPN3;
                    else
                      disp("Large Laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN3;
                    end
                    
       case 3    
                      if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                    
                     ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon2;
end
EGENHEAT=EGENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      EGENHEAT=EGENHEAT+HeatWPN2;
                    end
                     if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon3;
end
EGENHEAT=EGENHEAT+HeatWPN3;
                    else
                      disp("large Laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN3;
                    end
       case 4
           APHASE=3;
            end
   end
        if LT <=0
            attack=input("Please select a weapon to fire. 1. Fires medium laser 2. Fires large laser. 3 Alpha strike (fires all). 4. Do not fire: ")
          switch attack
              case 1
                   if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon1;
end
EGENHEAT=EGENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN1;
                    end
                    
              case 2
                   if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon3;
end
EGENHEAT=EGENHEAT+HeatWPN3;
                    else
                      disp("large Laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN3;
                    end
              case 3
                   if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                      ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon1;
end
EGENHEAT=EGENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN1;
                    end
                     if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon3;
end
EGENHEAT=EGENHEAT+HeatWPN3;
                    else
                      disp("large Laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN3;
                    end
              case 4
                  APHASE=3;
                  
        end
        end
            if LA<=0
                attack=input("Please select a weapon to fire. 1. Fires medium laser 2.Fires Auto Cannon. 3 Alpha strike (fires all). 4. Do Not Fire: ") 
           switch attack
               
               case 1
                    if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                       ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon1;
end
EGENHEAT=EGENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN1;
                    end
                    
               case 2
                    if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                     ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon2;
end
EGENHEAT=EGENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      EGENHEAT=EGENHEAT+HeatWPN2;
                    end
               case 3
                    if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon1;
end
EGENHEAT=EGENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN1;
                    end
                     if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon2;
end
       EGENHEAT=EGENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      EGENHEAT=EGENHEAT+HeatWPN2;
                    end
               case 4
                   APHASE=3;
           end
            end
        case 1
            if LA<=0 & LT<=0
               attack=input("Please select a weapon to fire. 1 Fires medium laser 2. Do not fire")
               switch attack
                   case 1
                    if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon1;
end
EGENHEAT=EGENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN1;
                    end 
                   case 2
                       APHASE=3;
               end
              
            if RA<=0&LA<=0
                attack=input("Please select a weapon to fire. 1 Fires Auto Cannon 2. Do not fire")
                switch attack
                    case 1
                         if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon2;
end
EGENHEAT=EGENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      EGENHEAT=EGENHEAT+HeatWPN2;
                    end  
                
                    case 2
                        APHASE=3;
                end
                
            end
            if RA<=0 & LA<=0
              attack=input("Please select a weapon to fire. 1 Large laser 2. Do not fire")
              switch attack
                  case 1
                    if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                      
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        RA=RA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        RL=RL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        RT=RT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        CT=CT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        LT=LT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        LL=LL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        LA=LA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        Head=Head-Weapon3;
end
EGENHEAT=EGENHEAT+HeatWPN3;
                    else
                      disp("large Laser missed")
                      EGENHEAT=EGENHEAT+HeatWPN3;
                    end
                  case 2
                       APHASE=3;
              end
              
            end
            end
        case 0
            disp("All off your weapons have been destroyed!")
    end
    
disp("PLAYER 1 TURN")
  disp("You have "),disp(NUMWEAP), disp(" Do you wish to fire?")
    switch NUMWEAP
        case 3 --%all weapons intacted
            attack=input("Please select a number to fire aweapon. 1. Fires medium Laser. 2. Fires Auto cannon. 3. Fires large laser. 4 Alpha strike (fires all). 5.Do not fire : ")
             
            DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                    
            switch attack
                case 1 --%case 1 selection
                    
                    DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                    
                   if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    
                       
             
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon1;
end
GENHEAT=GENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      GENHEAT=GENHEAT+HeatWPN1;
                    end
                    
                
                case 2 --%case 1 selection
                        DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                    
                    if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2|| ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2|| ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                    
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon2;
end
GENHEAT=HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      GENHEAT=HeatWPN2;
                    end
                    
                case 3 --%case 1 selection
                    if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                    
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon3;
end
GENHEAT=HeatWPN3;
                    else
                        disp("Small Laser missed")
                      GENHEAT=HeatWPN3;
                    end
                    
                case 4 --%case 1 overall selection
                    
                     if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon1;
end
GENHEAT=GENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      GENHEAT=GENHEAT+HeatWPN1;
                    end
                     if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon2;
end
GENHEAT=GENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      GENHEAT=GENHEAT+HeatWPN2;
                    end
                     if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon3;
end
GENHEAT=GENHEAT+HeatWPN3;
                    else
                      disp("Large Laser missed")
                      GENHEAT=GENHEAT+HeatWPN3;
                    end
                case 5
                    APHASE=3;
            end
            
        case 2  --%1 weapon destroyed
            if RA<=0
                attack=input("Please select a weapon to fire. 1. Fires Auto cannon. 2. Fires small laser. 3 Alpha strike (fires all). 4.Do not fire : ")
                 DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                    
   switch attack
       case 1
                  
                  if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 & ADIST>MRangeWPN2
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon2;
end
GENHEAT=HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      GENHEAT=HeatWPN2;
                    end
       case 2
           DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                    if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon3;
end
GENHEAT=GENHEAT+HeatWPN3;
                    else
                      disp("Large Laser missed")
                      GENHEAT=GENHEAT+HeatWPN3;
                    end
                    
       case 3    
                     DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                      if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                    
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon2;
end
GENHEAT=GENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      GENHEAT=GENHEAT+HeatWPN2;
                    end
                     if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon3;
end
GENHEAT=GENHEAT+HeatWPN3;
                    else
                      disp("large Laser missed")
                      GENHEAT=GENHEAT+HeatWPN3;
                    end
       case 4
           APHASE=3;
            end
   end
        if LT <=0
            DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
            attack=input("Please select a weapon to fire. 1. Fires medium laser 2. Fires large laser. 3 Alpha strike (fires all). 4. Do not fire: ")
             DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                    
          switch attack
              case 1
                   if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon1;
end
GENHEAT=GENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      GENHEAT=GENHEAT+HeatWPN1;
                    end
                    
              case 2
                   if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon3;
end
GENHEAT=GENHEAT+HeatWPN3;
                    else
                      disp("large Laser missed")
                      GENHEAT=GENHEAT+HeatWPN3;
                    end
              case 3
                   if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon1;
end
GENHEAT=GENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      GENHEAT=GENHEAT+HeatWPN1;
                    end
                     if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon3;
end
GENHEAT=GENHEAT+HeatWPN3;
                    else
                      disp("large Laser missed")
                      GENHEAT=GENHEAT+HeatWPN3;
                    end
              case 4
                  APHASE=3;
                  
        end
        end
            if LA<=0
                attack=input("Please select a weapon to fire. 1. Fires medium laser 2.Fires Auto Cannon. 3 Alpha strike (fires all). 4. Do Not Fire: ") 
                DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
           switch attack
               
               case 1
                    if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon1;
end
GENHEAT=GENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      GENHEAT=GENHEAT+HeatWPN1;
                    end
                    
               case 2
                    if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon2;
end
GENHEAT=GENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      GENHEAT=GENHEAT+HeatWPN2;
                    end
               case 3
                    if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon1;
end
                    else
                        disp("Medium laser missed")
                      GENHEAT=GENHEAT+HeatWPN1;
                    end
                     if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon2;
end
       GENHEAT=GENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      GENHEAT=GENHEAT+HeatWPN2;
                    end
               case 4
                   APHASE=3;
           end
            end
        case 1
            if LA<=0 & LT<=0
                DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
               attack=input("Please select a weapon to fire. 1 Fires medium laser 2. Do not fire")
               switch attack
                   case 1
                    if ADIST==SRangeWPN1 || ADIST<SRangeWPN1
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN1 || ADIST < MRangeWPN1 && ADIST>SRangeWPN1
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN1 || ADIST < LRangeWPN1 && ADIST>MRangeWPN1
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    if ATTROLL>= ATTCHECK
                        --display hit message and dmg location
                        
PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon1;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon1;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon1;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon1;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon1;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon1;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon1;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon1;
end
GENHEAT=GENHEAT+HeatWPN1;
                    else
                        disp("Medium laser missed")
                      GENHEAT=GENHEAT+HeatWPN1;
                    end 
                   case 2
                       APHASE=3;
               end
              
            if RA<=0&LA<=0
                attack=input("Please select a weapon to fire. 1 Fires Auto Cannon 2. Do not fire")
                DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
                switch attack
                    case 1
                         if ADIST==SRangeWPN2 || ADIST<SRangeWPN2
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN2 || ADIST < MRangeWPN2 && ADIST>SRangeWPN2
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN2 || ADIST < LRangeWPN2 && ADIST>MRangeWPN2
                        RANGES=3;
                    end
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2); 
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon2;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon2;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon2;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon2;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon2;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon2;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon2;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon2;
end
GENHEAT=GENHEAT+HeatWPN2;
                    else
                        disp("Auto cannon missed")
                      GENHEAT=GENHEAT+HeatWPN2;
                    end  
                
                    case 2
                        APHASE=3;
                end
                
            end
            if RA<=0 & LA<=0
              attack=input("Please select a weapon to fire. 1 Large laser 2. Do not fire")
              DIST=sqrt((EPOSX-PPOSX)^2+(EPOSY-PPOSY)^2);
                    ADIST=DIST/1.732;
              switch attack
                  case 1
                    if ADIST==SRangeWPN3 || ADIST<SRangeWPN3
                        RANGES=1;
                    end
                    
                    if ADIST == MRangeWPN3 || ADIST < MRangeWPN3 && ADIST>SRangeWPN3
                        RANGES=2;
                    end
                    
                    if ADIST == LRangeWPN3 || ADIST < LRangeWPN3 && ADIST>MRangeWPN3
                        RANGES=3;
                    end
                      
                    ATTCHECK=Gunnery+ESPEEDPEN-PSPEEDPEN+RANGES;
                    ATTROLL=MULTIDICE(6,2);
                    
                    if ATTROLL>= ATTCHECK
                    PARoll=MULTIDICE(6,2);
switch PARoll
    case 2
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 3
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 4
        disp("The enemy is hit in the Right Arm")
        ERA=ERA-Weapon3;
    case 5
        disp("The enemy is hit in the Right Leg")
        ERL=ERL-Weapon3;
    case 6
        disp("The enemy is hit in the Right Torso")
        ERT=ERT-Weapon3;
    case 7
        disp("The enemy is hit in the center torso")
        ECT=ECT-Weapon3;
    case 8
        disp("The enemy is hit in the Left torso")
        ELT=ELT-Weapon3;
    case 9
        disp("The enemy is hit in the Left Leg")
        ELL=ELL-Weapon3;
    case 10
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 11
        disp("The enemy is hit in the Left Arm")
        ELA=ELA-Weapon3;
    case 12
        disp("The enemy is hit in the head")
        EHead=EHead-Weapon3;
end
GENHEAT=GENHEAT+HeatWPN3;
                    else
                      disp("large Laser missed")
                      GENHEAT=GENHEAT+HeatWPN3;
                    end
                  case 2
                       APHASE=3;
              end
              
            end
            end
        case 0
            disp("All off your weapons have been destroyed!")
    end
end
--apply damage correctly
if LA<= 0
     disp("Player 1 Left Arm destroyed")
PEXCESS=0-LA;
LA=0;
LT=LT-PEXCESS;
PEXCESS=0;
NUMWEAP=NUMWEAP-1;
end
if RA<= 0
    disp("Player 1 Right Arm destroyed")
PEXCESS=0-RA;
RA=0;
RT=RT-PEXCESS;
PEXCESS=0;
end
if LL<= 0
    disp("Player 1 Left Leg destroyed")
PEXCESS=0-LL;
LL=0;
LT=LT-PEXCESS;
PEXCESS=0;
end
if RL<= 0
    disp("Player 1 Right Leg destroyed")
PEXCESS=0-RL;
RL=0;
RL=RL-PEXCESS;
PEXCESS=0;
end
if RT<= 0
    disp("Player 1 Right Torso destroyed")
PEXCESS=0-RT;
RT=0;
CT=CT-PEXCESS;
PEXCESS=0;
end
if LT<= 0
    disp("Player 1 Left Torso destroyed")
PEXCESS=0-LT;
LT=0;
CT=CT-PEXCESS;
PEXCESS=0;
NUMWEAP=NUMWEAP-1;
end
if ELA<= 0
    disp("Player 2 Left arm destroyed")
EEXCESS=0-ELA;
LA=0;
ELT=ELT-EEXCESS;
EEXCESS=0;
ENUMWEAP=ENUMWEAP-1;
end
if ERA<= 0
    disp("Player 2 Right arm destroyed")
EEXCESS=0-ERA;
ERA=0;
ERT=ERT-EEXCESS;
EEXCESS=0;
ENUMWEAP=ENUMWEAP-1;
end
if ELL<= 0
    disp("Player 2 Left Leg destroyed")
EEXCESS=0-ELL;
ELL=0;
ELT=ELT-EEXCESS;
EEXCESS=0;
end
if ERL<= 0
    disp("Player 2 Right Leg destroyed")
EEXCESS=0-ERL;
ERL=0;
ERL=ERL-EEXCESS;
EEXCESS=0;
end
if ERT<= 0
    disp("Player 2 Right Torso destroyed")
EEXCESS=0-ERT;
ERT=0;
ECT=ECT-EEXCESS;
EEXCESS=0;
end
if ELT<= 0
    disp("Player 2 Left Torso destroyed")
EEXCESS=0-ELT;
ELT=0;
ECT=ECT-EEXCESS;
EEXCESS=0;
ENUMWEAP=ENUMWEAP-1;
end
--end of game conditions
if ECT!=0 --Conditions for enemy defeat
    Continue=0;
else
    Continue=1;
    ENDGAME=0;
end
if EHead!=0
    Continue=0;
else
    Continue=1;
    ENDGAME=0;
end
if CT!=0  --Conditions for player defeat
    Continue=0;
else
    Continue=1;
    ENDGAME=1;
end
if Head!=0  --Conditions for player defeat
    Continue=0;
else
    Continue=1;
    ENDGAME=1;
end
if CT<=0 && ECT<=0 --Conditions for Draw
    Continue=1;
    ENDGAME=3;
else
    Continue=0;
end
if Head<=0 && EHead <=0 --Conditions for Draw
    Continue=1;
    ENDGAME=3;
else
    Continue=0;
end
   
Quit=input("Do you wish to continue? (y/n): ","s");-- Quit option
switch Quit
    case 'Y'
         Continue=0;
    case 'y'
         Continue=0;
    case 'YES'
         Continue=0;
    case 'yes'
         Continue=0;
    otherwise 
        Continue=1;
        ENDGAME=2;
end
                  
--Heat phase
HEAT=GENHEAT-HeatSink;
if HEAT>0
   if HEAT>= 5&& HEAT<=9
       STAT=-1;
   end
   if HEAT<9 && HEAT<=14
       STAT=-2;
   end
   if HEAT<14 && HEAT<=19
       STAT=-3;
   end
   
    if HEAT>= 8&& HEAT<=12
       STAT2=-1;
   end
   if HEAT<12 && HEAT<=16
       STAT2=-2;
   end
   if HEAT<16 && HEAT<=21
       STAT2=-3;
   end
   Pilot1=Pilot;
   Pilot=Pilot+STAT;
   Gunnery1=Gunnery;
   Gunnery=Gunnery+STAT2;
   GENHEAT=HEAT;
else
    Pilot=Pilot1;
    Gunnery=Gunnery1;
    GENHEAT=0;
end
    
       
EHEAT=EGENHEAT-HeatSink;
if EHEAT>0
   if EHEAT>= 5&& EHEAT<=9
       ESTAT=-1;
   end
   if HEAT<9 && EHEAT<=14
       ESTAT=-2;
   end
   if EHEAT<14 && EHEAT<=19
       ESTAT=-3;
   end
   
    if EHEAT>= 8 && EHEAT<=12
       ESTAT2=-1;
   end
   if EHEAT<12 && EHEAT<=16
       ESTAT2=-2;
   end
   if EHEAT<16 && EHEAT<=21
       ESTAT2=-3;
   end
   EPilot1=EPilot;
   EPilot=EPilot+ESTAT;
   EGunnery1=EGunnery;
   EGunnery=EGunnery+ESTAT2;
   EGENHEAT=EHEAT;
else
    EPilot=EPilot1;
    EGunnery=EGunnery1;
    EGENHEAT=0;
end
NUMWEAP=3;
ENUMWEAP=3;
--end of round
disp("End of Round "),disp(Round)
disp("Player 1 heat level is "), disp(GENHEAT)
disp("Player 2 heat level is "), disp(EGENHEAT)
    
--end big loop
end
switch ENDGAME
    case 0
        disp("Player 1 Wins!!")
    case 1
        disp("Player 2 Wins!!")
    case 2
        disp("You have fled the battle!")
    case 3
        disp("Draw! You have killed each other")
end
DICE mfile:
function out=DICE(n)
--simulates a dice roll
--Enter the number of sides of the dice
Total=1;
k=0;
m=1;
while k!=n-1
    
    Roll=randn(m);
    if Roll >= 0
        Roll=1;
    else 
        Roll=0;
    end
    Total=Total+Roll;
    k=k+1;
end
out=Total;
MULTIDICE MFILE
function z=MULTIDICE(x,y)
--MULTIDICE simulates the throwning of multiple dice
--x is the number of sides of the dice
--y is the number of dice wished to be thrown
Total=0;
for n=1:y
    Roll=DICE(x);
    Total=Total+Roll;
end
z=Total;
}
