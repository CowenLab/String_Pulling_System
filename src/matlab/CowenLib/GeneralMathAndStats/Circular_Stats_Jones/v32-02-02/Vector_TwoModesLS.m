
function F = Vector_TwoModesLS(x, CSarr)

%Vector_TwoModesLS.m

% Copyright C 2004  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Calculates the 6 terms F in the function that is being optimized
% for separating the components of a mixture of two von Mises dists.

% Variables input:
%  x = 5-component vector of current estimates of parameters
%   x(1) = kappa 1    x(2) = theta 1
%   x(3) = kappa 2    x(4) = theta 2
%   x(5) = alfa (proportion of N for mode 1 vs all N)
%  CSarr = 6-component array of trig moments
%   1: sum(cos(Azim))/N  2: sum(cos(2*Azim))/N   3: sum(cos(3*Azim))/N
%   4: sum(sin(Azim))/N  5: sum(sin(2*Azim))/N   6: sum(sin(3*Azim))/N
% Variable output:
%  F = vector of 6 calculated terms  

% Reference: Fisher, 1993, p. 97 

% set up useful functions

besl10 = besseli(0, x(1));
besl11 = besseli(1, x(1));
besl30 = besseli(0, x(3));
besl31 = besseli(1, x(3));

A11 = besl11/besl10;
A12 = 1 - 2*A11/x(1);
A13 = A11 - 4*A12/x(1);
A31 = besl31/besl30;
A32 = 1 - 2*A31/x(3);
A33 = A31 - 4*A32/x(3);

%calculate components of F

F(1) = x(5)*A11*cos(x(2))   + (1-x(5))*A31*cos(x(4))   - CSarr(1);
F(2) = x(5)*A12*cos(2*x(2)) + (1-x(5))*A32*cos(2*x(4)) - CSarr(2);
F(3) = x(5)*A13*cos(3*x(2)) + (1-x(5))*A33*cos(3*x(4)) - CSarr(3);
F(4) = x(5)*A11*sin(x(2))   + (1-x(5))*A31*sin(x(4))   - CSarr(4);
F(5) = x(5)*A12*sin(2*x(2)) + (1-x(5))*A32*sin(2*x(4)) - CSarr(5);
F(6) = x(5)*A13*sin(3*x(2)) + (1-x(5))*A33*sin(3*x(4)) - CSarr(6);


    