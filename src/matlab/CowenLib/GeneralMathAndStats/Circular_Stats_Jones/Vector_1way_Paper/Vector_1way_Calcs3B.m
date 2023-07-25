function RtrnCode = Vector_1way_Calcs3B(q, UseFrq, Azims, ...
                                        SummaryStats, NB, alfa, fidO);

%Vector_1way_Calcs3B.m 

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Performs the statistical tests for the equality of all Kappas.
% This uses bootstrap/resampling methods with the tangential method.

% Input variables:
%   q: number of samples to be analyzed
%   UseFrq: 0 = data input as individual azimuths
%           1 = data input as azimuth column, plus q columns of counts
%   Azims: Array of azimuths to be processed, in radians
%   SummaryStats: array of size q+1,8 containing calculated summary stats
%         for each of q samples and total combined sample (row q+1)
%         Columns contain:  1) sum(sines)     2) sum(cosines)     3) N
%            4) R-squared     5) R      6) R-bar    
%            7) Vector mean, theta (degrees)   8) Concentration (kappa)
%   NB: number of bootstrap iterations to make
%   alfa: Level of significance: should be in range (0.001 - 0.25)
%   fidO: output file for writing calculations if fidO > 0
% Output variable:
%   RtrnCode: return code

% Functions and scripts called from this module:
%   Vector_1way_Bootstrap_TestKappa.m

%  setup / calculate some values

RtrnCode = 0;

CatN = SummaryStats(1:q+1, 3);  CatTheta = SummaryStats(1:q, 7);
NTot = SummaryStats(q+1, 3);

ptskip=sprintf('\n');
ptminus=sprintf('---------------------------------------------------\n');
ptequal=sprintf('===================================================\n');

pt1A = sprintf(['USE RANDOMIZATION/RESAMPLING TO TEST EQUALITY OF', ...
                ' ALL q CONCENTRATIONS (KAPPA)']);   
disp(ptskip); disp(ptequal); disp(ptskip); disp(pt1A); disp(ptskip);
if fidO > 0
    fprintf(fidO, ptskip); fprintf(fidO, ptequal); fprintf(fidO, ptskip);
    fprintf(fidO, [pt1A,'\n']);   fprintf(fidO, ptskip);
end
    
pt40 = sprintf('Ho: All q Kappas (concentrations) are equal');
disp(pt40); disp(ptskip);
if fidO > 0
    fprintf(fidO, ptskip); fprintf(fidO, [pt40,'\n']);
    fprintf(fidO, ptskip);
end  
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

% Process with RANDOMIZATION/bootstrap to test for equality of q Kappas
% (Fisher, 1993, p. 132, 214-216)

[fr, TestCut, Pvalue] = Vector_1way_Bootstrap_TestKappa(q, ...
                                UseFrq, Azims, CatN, CatTheta, ...
                                NB, alfa);

% output results

pt11 = sprintf('   Tangential method with Randomization');
pt12 = sprintf('   Under Ho, test cutoff = %.5g', ...
                TestCut);
pt13 = sprintf('   Calculated test statistic = %.5g', fr);
pt14 = sprintf('   Pvalue = %6.3f (approximate)',Pvalue);
if Pvalue <= alfa
    pt15 = sprintf('   Reject Ho at significance level %.3g', alfa);   
else
    pt15 = sprintf(['   Fail to reject Ho at significance level'...
                    ' %.3g'], alfa);
end
ptref = sprintf('   Ref.: Fisher, 1993, p. 132, 214-216\n');
disp(pt11); disp(pt12); disp(pt13); disp(pt14); disp(pt15);
disp(ptref); disp(ptskip);
if fidO > 0
  fprintf(fidO, [pt11,'\n']);
  fprintf(fidO, [pt12,'\n']); fprintf(fidO, [pt13,'\n']);
  fprintf(fidO, [pt14,'\n']); fprintf(fidO, [pt15,'\n']);
  fprintf(fidO, [ptref,'\n']);
  fprintf(fidO, ptskip);
end

