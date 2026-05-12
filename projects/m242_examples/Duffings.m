function [T,Y] = Duffings(Y0,tau_0,tau_f,eta,epsilon,sigma,PlotFlag)
% Solve dimensionless Duffings DE for a<= tau <= b
% starting from initial state (T0,Y0] (Y0 a column of y0, v0=ydot0)
% ending at final state (Tf,Yf)
% If PlotFlag is present (any value), a solution plot is made.
 
% create rate function
F = @(tau,Y) [Y(2);-Y(1)-epsilon*Y(2).^3-2*eta*Y(2)+cos(sigma*tau)];

% Call the DE solver
[T,Y]=ode45(F,[tau_0,tau_f],Y0);

if nargin >6
    subplot(3,1,1)
    plot(T,Y(:,1),'b')
    xlabel('t')
    ylabel('y (position)')
    title(['Duffings DE from (t_0,y_0,v_0) = (',num2str(tau_0),' ,',num2str(Y0(1)),...
        ' ',num2str(Y0(2)),'): parameters \eta = ',num2str(eta),...
        'eps = ',num2str(epsilon),'\sigma = ',num2str(sigma)])
    subplot(3,1,2)
    plot(T,Y(:,2),'r')
    xlabel('t')
    ylabel('v (velocity)')
    title('velocity (t,v)')
    subplot(3,1,3)
    plot(Y(:,1),Y(:,2),'g')
    xlabel('y (position')
    ylabel('v (velocity)')
    title('phase plot (y,ydot)')
    hold
    plot(Y(1,1),Y(1,2),'rp')
    hold off
end


