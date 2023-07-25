function RtrnCode = Vector_1way_Calcs1B(q, UseFrq, Azims, SummaryStats, ...
                                        BSeq, BSne, NB, alfa, fidO);

%Vector_1way_Calcs1B.m 

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Performs the statistical tests for equality of vector means.
% Uses resampling/bootstrap method.
% Tests assuming:  
%     1) Kappas are equal, and vonMises assumed.
%     2) Kappas not equal (heterogeneous), and non-parametric assumed.

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
%   BSeq: Do calculations assuming equal kappas?  0=no; 1=yes    
%   BSne: Do calculations assuming unequal kappas?  0=no; 1=yes   
%   NB: number of bootstrap iterations
%   BSRS: do bootstraps even if not required by N (1) - else dont (0)
%   alfa: Level of significance: should be in range (0.001 - 0.25)
%   fidO: output file for writing calculations if fidO > 0
% Generated variable:
%   Nlimit1: do standard tests if all subsample sizes exceed this
%   Nlimit2: do bootstrap if all subsample sizes less than this
%   CalcsToDo: Do each individual test for corresp. entries in array?
%              yes = 1; 0 = no
%   BSeqK: do bootstrap assuming equal Kappas? 0=no, 1=yes
%   BSneK: do bootstrap assuming not-equal Kappas? 0=no, 1=yes
% Output variable:
%   RtrnCode: return code

% Functions and scripts called from this module:
%   Vector_1way_Bootstrap_TstMnsVM.m
%   Vector_1way_Bootstrap_TestMeans.m
 
%  setup / calculate some values

RtrnCode = 0;

CatN = SummaryStats(1:q, 3);
CatRbar = SummaryStats(1:q, 6);
CatTheta = SummaryStats(1:q, 7);
CatKappa = SummaryStats(1:q, 8);
NTot = SummaryStats(q+1, 3);

ptskip=sprintf('\n');
ptminus=sprintf('---------------------------------------------------\n');
ptequal=sprintf('===================================================\n');

pt1A = sprintf(['USE RESAMPLING/BOOTSTRAP TO TEST EQUALITY FOR', ...
                ' ALL q VECTOR-MEANS']);   
disp(ptskip); disp(ptequal); disp(ptskip); disp(pt1A); disp(ptskip);
if fidO > 0
    fprintf(fidO, ptskip); fprintf(fidO, ptequal); fprintf(fidO, ptskip);
    fprintf(fidO, [pt1A,'\n']);   fprintf(fidO, ptskip);
end
    
if BSeq > 0
    
pt40 = sprintf('Ho: All q Vector-mean directions are equal');
disp(pt40); disp(ptskip);
if fidO > 0
    fprintf(fidO, ptskip); fprintf(fidO, [pt40,'\n']);
    fprintf(fidO, ptskip);
end  
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

% Start processing with Von Mises - based resampling (Monte Carlo simulation)
% to test for equality of q vector means
% (Fisher, 1993, p. 124-125, 213-214)  

[Yr, TestCut, Pvalue] = Vector_1way_Bootstrap_TstMnsVM(q, ...
                                CatN, CatRbar, CatTheta, CatKappa,...
                                NB, alfa);

% output results

pt11 = sprintf('   Von Mises distribution with resampling method');
pt12 = sprintf('   Under Ho, Resampled test cutoff = %.5g', ...
                TestCut);
pt13 = sprintf('   Calculated test statistic = %.5g', Yr);
pt14 = sprintf('   Pvalue = %6.3f (approximate)',Pvalue);
if Pvalue <= alfa
    pt15 = sprintf('   Reject Ho at significance level %.3g', alfa);   
else
    pt15 = sprintf(['   Fail to reject Ho at significance level'...
                    ' %.3g'], alfa);
end
ptref = sprintf('   Ref.: Fisher, 1993, p. 124-125, 213-214\n');
disp(pt11); disp(pt12); disp(pt13); disp(pt14); disp(pt15);
disp(ptref); disp(ptskip);
if fidO > 0
  fprintf(fidO, [pt11,'\n']);
  fprintf(fidO, [pt12,'\n']); fprintf(fidO, [pt13,'\n']);
  fprintf(fidO, [pt14,'\n']); fprintf(fidO, [pt15,'\n']);
  fprintf(fidO, [ptref,'\n']);
  fprintf(fidO, ptskip);
end

end

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

% Start processing with non-parametric bootstrap
% to test for equality of q vector means
% (Fisher, 1993, p. 115-117, 34-35, 213-214)

if BSne > 0
    
pt40 = sprintf('Ho: All q Vector-mean directions are equal');
disp(pt40); disp(ptskip);
if fidO > 0
    fprintf(fidO, ptskip); fprintf(fidO, [pt40,'\n']); 
    fprintf(fidO, ptskip);
end 

[Yr, TestCut, Pvalue, DelRatio] = Vector_1way_Bootstrap_TestMeans( ...
                                   q, UseFrq, Azims, ...
                                   CatN, CatTheta, NB, alfa);

% output results

pt11 = sprintf(['   Non-parametric, bootstrap version of ', ...
                'heterogeneity method']);
if DelRatio <= 4
    pt16 = sprintf('   Uses P method: Delta ratio = %.1f', DelRatio); 
else
    pt16 = sprintf('   Uses M method: Delta ratio = %.1f', DelRatio); 
end
pt12 = sprintf('   Under Ho, Bootstrapped test cutoff = %.5g', ...
                TestCut);
pt13 = sprintf('   Calculated test statistic = %.5g', Yr);
pt14 = sprintf('   Pvalue = %6.3f (approximate)',Pvalue);
if Pvalue <= alfa
    pt15 = sprintf('   Reject Ho at significance level %.3g', alfa);
else
    pt15 = sprintf(['   Fail to reject Ho at significance level'...
                    ' %.3g'], alfa);
end
ptref = sprintf('   Ref.: Fisher, 1993, p. 115-117, 34-35, 213-214\n');
disp(pt11); disp(pt16); 
disp(pt12); disp(pt13); disp(pt14); disp(pt15);
disp(ptref);
if fidO > 0
  fprintf(fidO, [pt11,'\n']); fprintf(fidO, [pt16,'\n']);
  fprintf(fidO, [pt12,'\n']); fprintf(fidO, [pt13,'\n']);
  fprintf(fidO, [pt14,'\n']); fprintf(fidO, [pt15,'\n']);
  fprintf(fidO, [ptref,'\n']);
  fprintf(fidO, ptskip);
end

end
