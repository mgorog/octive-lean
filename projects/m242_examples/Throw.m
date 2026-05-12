function percent_in=Throw(N,W,sigma)
% calculates the percentage of N (Normal Random) Throws
% That land in the box [-W/2, W/2]^3
% when the standard deviation is sigma
% in each dimension (x, y, z) 
% Sample Command and Results
(Normal Distribution theory gives sigma=.13852)
% >>Throw(1000000,.5,.1388)   80.114900000000006
% >>Throw(1000000,.5,.1388)   79.982100000000003
% Note: (Normal Distribution theory gives sigma=.13852)
% B. Lundberg, 4-2-2025
throw_pts=sigma*randn([N,3]);
w=W/2;
ins=find(throw_pts(:,1) >-w & throw_pts(:,2)> -w & throw_pts(:,3)> -w ...
       & throw_pts(:,1) < w & throw_pts(:,2)<  w & throw_pts(:,3)< w);
percent_in=100*length(ins)/N;
