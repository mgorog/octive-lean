
Loop_length = input('Enter Loop Length (positive integer, 10^8 suggested)  =  ') 

clear s d 

disp('Timings (tic, toc)  for loops with different memory allocations')

t0=tic;s(1)=-1;d=.1;for n=1:N, s(n+1)=exp(s(n))*cos(s(n)+d);end, t_dyn=toc(t0);

%_____________________________________

clear s d 

t0=tic;s=zeros([N+1,1]);t_mem=toc(t0);t0=tic;s(1)=-1; d=.1;for n=1:N,s(n+1)=exp(s(n))*cos(s(n)+d);end,t_loop=toc(t0);

%_____________________________________

clear s d 

t0=tic;s=zeros([N+1,1]);s(1)=-1;d=.1;for n=1:N, s(n+1)=exp(s(n))*cos(s(n)+d);end, t_comb=toc(t0);
disp([ ])
disp('t_dyn, t_mem, t_loop_ t_mem + t_loop, t_comb')
disp([t_dyn; t_mem; t_loop; t_mem+t_loop; t_comb])

% ___________________ cputime ______________________________

disp('Timings (cputimes)  for loops with different memory allocations')

clear s d 

 t0=cputime;s(1)=-1;d=.1;for n=1:N, s(n+1)=exp(s(n))*cos(s(n)+d);end, t_dyn=cputime-t0;

%_____________________________________

clear s d 

t0=cputime;s=zeros([N+1,1]);t_mem=cputime-t0;t0=cputime;s(1)=-1;d=.1;for n=1:N, s(n+1)=exp(s(n))*cos(s(n)+d);end, t_loop=cputime-t0;

%_____________________________________

clear s d 

t0=cputime;s=zeros([N+1,1]);s(1)=-1;d=.1;for n=1:N, s(n+1)=exp(s(n))*cos(s(n)+d);end, t_comb=cputime-t0;
disp([ ])
disp('t_dyn, t_mem, t_loop_ t_mem + t_loop, t_comb')
disp([t_dyn; t_mem; t_loop; t_mem+t_loop; t_comb])