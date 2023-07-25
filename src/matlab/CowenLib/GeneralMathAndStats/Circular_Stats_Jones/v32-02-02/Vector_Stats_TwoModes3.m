function RtrnCode = Vector_Stats_TwoModes3(NTot, Azims, fidO)

%Vector_Stats_TwoModes3.m

% Copyright C 2004  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Bimodal fit of circular data - separates out two components of mixture 
%    Special case with three parameters (modes 180 deg apart, 
%    concentrations equal)

% Input variables:
%   NTot: N, sample size
%   Azims: Azimuths to be processed, in radians
%   fidO: output file for writing calculations
% Output variable:
%   RtrnCode: Error return

% Functions and scripts called from this module:
%   SolveA2.m

RtrnCode = 0;

ptskip=sprintf('\n');
ptminus=sprintf('---------------------------------------------------\n');

disp(ptskip); disp(ptminus); disp(ptskip)
pt1 = sprintf(['Separate two von Mises components from a mixture\n',...
               'Special three-parameter case\n']);
pt2 = sprintf('(Ref: Fisher, 1993, p. 99 - 100)\n'); 
disp(pt1); disp(pt2); disp(ptskip)
if fidO > 0
     fprintf(fidO, ptskip); fprintf(fidO, ptminus);
     fprintf(fidO, ptskip); fprintf(fidO, pt1); fprintf(fidO, pt2);
     fprintf(fidO, ptskip);
end

% Calculate moments and basic stats 

psi = Azims;
for iiii=1:NTot
    if psi(iiii) > pi
        psi(iiii) = psi(iiii) - pi;
    end
end
Cpsi = sum(cos(2*psi));
Spsi = sum(sin(2*psi));
C1 = sum(cos(Azims))/NTot;
S1 = sum(sin(Azims))/NTot;

Rbarpsi = sqrt(Cpsi^2 + Spsi^2)/NTot;
mupsi = VectMean_arctan(Spsi, Cpsi);

% estimate parameters
 
estimates(1) = 0.5*mupsi;
estimates(2) = SolveA2(Rbarpsi);
aaa = C1*cos(estimates(1)) + S1*sin(estimates(1));
bbb = CalcKappa(estimates(2), 1);
estimates(3) = (1 + aaa/bbb)/2;

if NTot < 20
    KH = estimates(2)
    if KH < 2
        KappaHatCorr = max(KH - 2/(NTot*KH), 0);
    else
        KappaHatCorr = KH*(NTot - 1)^3 / (NTot + NTot^3);
    end
else
    KappaHatCorr = -99;
end

% output estimates of the two components

pt5=sprintf(['   Estimates of two components: \n', ...
             '   Mean, Kappa, Proportion\n', ...
             '   %.1f, %.5g, %.3f \n'], ...
             estimates(1), estimates(2), estimates(3));
pt6=sprintf(['   Kappa-hat corrected for small-sample bias = %.5g \n', ...
             '       (Ref.: Fisher, 1993, p. 88 (4.41))\n'], ...
              KappaHatCorr); 
         
disp(ptskip); disp(pt5); 
if KappaHatCorr > -9
    disp(pt6); 
end
disp(ptskip)
if fidO > 0
    fprintf(fidO, ptskip);
    fprintf(fidO, pt5);  
    if KappaHatCorr > -9
        fprintf(fidO, pt6);
    end
    fprintf(fidO, ptskip);
end

