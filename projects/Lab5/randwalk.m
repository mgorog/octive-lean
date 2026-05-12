function [x,y]=randwalk(s)
% Computes and plots (using comet function)
% a random walk of s steps from (0,0)
%Problem4-9 Solution (Written as a function instead)

x=zeros(1,s+1); % grab enought static memory
y=x;
plot(x(1),y(1),'bp')
hold on
rand('state',sum(100*clock))
for i=1:s;
    r=rand;
    if r<.25;
        x(i+1)=x(i)+1;
        y(i+1)=y(i);
    elseif r<.5;
        x(i+1)=x(i)-1;
        y(i+1)=y(i);
    elseif r<.75;
        x(i+1)=x(i);
        y(i+1)=y(i)+1;
    else
        x(i+1)=x(i);
        y(i+1)=y(i)-1;
    end
end
 disp('Plotting results...');
    toolkits = available_graphics_toolkits();
    if any(strcmp(toolkits, 'gnuplot'))
        graphics_toolkit('gnuplot');
    elseif any(strcmp(toolkits, 'fltk'))
        graphics_toolkit('fltk');
    elseif any(strcmp(toolkits, 'qt'))
        graphics_toolkit('qt');

    else
        disp('No graphics toolkit available. Plotting skipped.');
        return;
    end
comet(x,y)


