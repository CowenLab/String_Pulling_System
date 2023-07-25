function RtrnCode = Vector_Stats_TwoModes5(NTot, Azims, init_guesses,...
                                           fidO, MaxItr, TolerX)

%Vector_Stats_TwoModes5.m

% Copyright C 2004  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced.
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Bimodal fit of circular data - separates out two components of mixture 
% Sets up to use LS algorithm for fit
% See Fisher, 1993, p 97 (note typo on Kappa2 in (4.58)

% Input variables:
%   NTot: N, sample size
%   Azims: Azimuths to be processed, in radians
%   init_guesses: Initial estimates of the parameters, in order:
%         Kappa1, Mean1, Kappa2, Mean2, proportion1
%   fidO: output file for writing calculations
%   MaxItr: maximum number of iterations
%   TolerX: tolerance for iterating
% Output variable:
%   RtrnCode: Error return

% Functions and scripts called from this module:
%   Vector_TwoModesLS.m

RtrnCode = 0;

ptskip=sprintf('\n');
ptminus=sprintf('---------------------------------------------------\n');

disp(ptskip); disp(ptminus); disp(ptskip)
pt1 = sprintf(['Separate two von Mises components from a mixture\n',...
               'Estimation of 5 parameters\n']);
pt2 = sprintf('(Ref: Fisher, 1993, p. 97; Matlab function lsqnonlin)\n'); 
disp(pt1); disp(pt2); disp(ptskip)
if fidO > 0
     fprintf(fidO, ptskip); fprintf(fidO, ptminus);
     fprintf(fidO, ptskip); fprintf(fidO, pt1); fprintf(fidO, pt2);
     fprintf(fidO, ptskip);
end

% Calculate trig moments used by least-squares method
    
C1 = cos(Azims);
C2 = cos(2*Azims);
C3 = cos(3*Azims);
S1 = sin(Azims);
S2 = sin(2*Azims);
S3 = sin(3*Azims);

CSarr = zeros(6,1);
CSarr(1) = sum(C1)/NTot;
CSarr(2) = sum(C2)/NTot;
CSarr(3) = sum(C3)/NTot;
CSarr(4) = sum(S1)/NTot;
CSarr(5) = sum(S2)/NTot;
CSarr(6) = sum(S3)/NTot;

pt10=sprintf(['   Calculated trigonometric averages\n', ...
              '             Avg Cos       Avg Sin\n']);
pt11=sprintf(['     1       %.5g      %.5g     \n', ...
              '     2       %.5g      %.5g     \n', ...
              '     3       %.5g      %.5g     \n'], ...
           CSarr(1), CSarr(4), CSarr(2), CSarr(5), CSarr(3), CSarr(6));

% set up for least-squares routine

pt5=sprintf(['   Initial estimates for iteration: \n', ...
             '   Kappa1, Mean1, Kappa2, Mean2, Proportion1\n', ...
             '   %.5g, %.1f, %.5g, %.1f, %.3f \n'], ...
             init_guesses(1), init_guesses(2)*57.3, ...
             init_guesses(3), init_guesses(4)*57.3, init_guesses(5));

lb = [0,    0,       0,    0,       0.05];
ub = [1000, 6.28318, 1000, 6.28318, 0.95];

pt6=sprintf(['   Lower bounds on estimates: \n', ...
             '   %.5g, %.1f, %.5g, %.1f, %.3f \n'], ...
             lb(1), lb(2)*57.3, lb(3), lb(4)*57.3, lb(5));
pt7=sprintf(['   Upper bounds on estimates: \n', ...
             '   %.5g, %.1f, %.5g, %.1f, %.3f \n'], ...
             ub(1), ub(2)*57.3, ub(3), ub(4)*57.3, ub(5));
         
disp(pt10); disp(pt11); disp(ptskip)
disp(pt5); disp(pt6); disp(pt7); disp(ptskip)
if fidO > 0
    fprintf(fidO, pt10); fprintf(fidO, pt11); 
    fprintf(fidO, ptskip); 
    fprintf(fidO, pt5); fprintf(fidO, ptskip); 
    fprintf(fidO, pt6); fprintf(fidO, ptskip);
    fprintf(fidO, pt7); fprintf(fidO, ptskip);
end
    
options = optimset('Display', 'iter', 'MaxIter', MaxItr, 'TolX', TolerX);

[x,resnorm,residual,exitflag,output] = lsqnonlin('Vector_TwoModesLS', ...
                                init_guesses, lb, ub, options, CSarr);

% estimates of the two components

estimates = x;
estimates(2) = estimates(2)*57.3;
estimates(4) = estimates(4)*57.3;

if exitflag > 0
    iter=output.iterations;
    pt10=sprintf('Function converged to solution in %.0f iterations\n',...
                     iter);
else
    RtrnCode = 21;
    if exitflag < 0
        pt10=sprintf(['Function did not converge to a solution\n', ...
                      'Following values show last results\n']); 
    else
        pt10=sprintf(['Maximum number of iterations exceeded %.0f\n',...
                      'Following values show last results\n'], MaxItr); 
    end
end

pt5=sprintf(['   Estimates of two components: \n', ...
             '   Kappa1, Mean1, Kappa2, Mean2, Proportion1\n', ...
             '   %.5g, %.1f, %.5g, %.1f, %.3f \n'], ...
             estimates(1), estimates(2), ...
             estimates(3), estimates(4), estimates(5));
         
disp(ptskip); disp(pt10); disp(ptskip); disp(pt5); disp(ptskip)
if fidO > 0
    fprintf(fidO, ptskip); fprintf(fidO, pt10); fprintf(fidO, ptskip);
    fprintf(fidO, pt5);  fprintf(fidO, ptskip);
end

