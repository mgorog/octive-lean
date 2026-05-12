% test_montecarlo.m
% Test script to demonstrate inner workings of Monte Carlo scripts and derivative plotter.
% Assumes all .m files in same directory or added paths.
% Saves plots to 'plots' subfolder with appropriate names.
% Run with small n for quick execution; increase for accuracy.
% Assumes plots are enabled in montecarlo.m and montecarloa.m (uncomment if needed).

clear; clc;
addpath('Other Coding Examples');  % For originals
if ~exist('plots', 'dir')
    mkdir('plots');  % Create subfolder if not exists
end
n = 10000;  % Number of points

% 1a: Original pi estimators with timing and saved plots
tic; mcpi_loop = montecarlo(n); t_loop = toc;
print -dpng 'plots/montecarlo_loop.png';
disp(['Loop version pi: ' num2str(mcpi_loop) ', Time: ' num2str(t_loop) 's']);

tic; mcpi_vec = montecarloa(n); t_vec = toc;
print -dpng 'plots/montecarloa_vector.png';
disp(['Vector version pi: ' num2str(mcpi_vec) ', Time: ' num2str(t_vec) 's']);

% 1b.i: ln2 estimator (no plot)
tic; mcln2 = montecarlo_ln2(n); t_ln2 = toc;
disp(['ln2 estimate: ' num2str(mcln2) ', Time: ' num2str(t_ln2) 's']);

% 1b.ii: pi via 3D (no plot)
tic; mcpi_3d = montecarlo_pi3d(n); t_3d = toc;
disp(['3D pi estimate: ' num2str(mcpi_3d) ', Time: ' num2str(t_3d) 's']);

% 1b.iii: 4D hypervolume and pi (no plot)
tic; [hypervol, mcpi_4d] = montecarlo_4d(n); t_4d = toc;
disp(['4D hypervolume: ' num2str(hypervol) ', pi: ' num2str(mcpi_4d) ', Time: ' num2str(t_4d) 's']);

% 2: Derivative plotter example with f(x) = sin(x), [0, 2pi], n=50
f = @(x) sin(x);
a = 0; b = 2*pi; np = 50;
dxdt = plotderivative(f, a, b, np);
print -dpng 'plots/derivative_sin.png';
disp('Derivative plotted and saved; check plots/derivative_sin.png for approximation to cos(x).');
