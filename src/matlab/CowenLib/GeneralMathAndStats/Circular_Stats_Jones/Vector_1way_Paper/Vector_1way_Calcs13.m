function RtrnCode = Vector_1way_Calcs13(q, SummaryStats,  ...
                                        N1, N2, alfa, fidO);

%Vector_1way_Calcs13.m

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Performs the statistical tests and calculations for tests of equality
% of the vector means, assuming vonMises distribution.
% Ordered: 1) Likelihood ratio, 2) Watson-Williams, 3) Embedding, 4) None
%          5) Heterogeneous   6) Test equal means AND kappas
% No bootstrap calculations here.

% Input variables:
%   q: number of samples to be analyzed
%   SummaryStats: array of size q+1,8 containing calculated summary stats
%         for each of q samples and total combined sample (row q+1)
%         Columns contain:  1) sum(sines)     2) sum(cosines)     3) N
%            4) R-squared     5) R      6) R-bar    
%            7) Vector mean, theta (degrees)   8) Concentration (kappa)
%   N1: minimum sample size to calculate
%   N2: should have greater N than this
%   alfa: Level of significance: should be in range (0.001 - 0.25)
%   fidO: output file for writing calculations if fidO > 0
% Output variable:
%   RtrnCode: return code

%  setup / calculate some values

RtrnCode = 0;

N = SummaryStats(q+1, 3);
R2 = SummaryStats(q+1, 4);  R = SummaryStats(q+1, 5);
minN = min(SummaryStats(1:q, 3));

ptskip=sprintf('\n');
ptminus=sprintf('---------------------------------------------------\n');
ptequal=sprintf('===================================================\n');

% Test for equal vector means (theta) AND equal kappas 
% Assumes Von Mises distributions

pt1A = sprintf(['TEST FOR EQUALITY OF ALL q VECTOR-MEANS ', ...
                'AND EQUALITY OF ALL q CONCENTRATIONS']);
pt2A = sprintf('Assume data follow Von Mises distribution');

pt10A = sprintf('Ho: All q Vector-mean directions are equal');
pt10B = sprintf('    AND   All q Kappas (concentrations) are equal \n');

disp(ptskip); disp(ptequal); disp(ptskip); disp(pt1A); disp(pt2A);
disp(ptskip); disp(pt10A); disp(pt10B); disp(ptskip);
if fidO > 0
    fprintf(fidO, ptskip); fprintf(fidO, [ptequal,'\n']); 
    fprintf(fidO, ptskip);
    fprintf(fidO, [pt1A,'\n']); fprintf(fidO, [pt2A,'\n']);
    fprintf(fidO, ptskip);
    fprintf(fidO, [pt10A,'\n']); fprintf(fidO, [pt10B,'\n']); 
    fprintf(fidO, ptskip);
end 

                  % Assumes kappas are small and Ns large - von Mises
                  % Mardia and Jupp, 2000, p. 138 (7.4.12)

if minN >= N1       
    UUU = 0;  
    for iii = 1:q;  
        UUU = UUU + SummaryStats(iii, 4)/SummaryStats(iii, 3);  
    end;
    test = 2*(UUU - R2/N);
    %distributed as chi-square with 2(q-1) df
    df1 = 2*(q - 1);
    Pvalue = 1 - chi2cdf(test, df1);
    pt11 = sprintf('   Small Kappa OK, but needs large sample size');
    pt12 = sprintf(['   Under Ho, test distributed as chi-square ', ...
                    'with%3.0f d.f.'], df1);
    pt13 = sprintf('   Test statistic = %.5g', test);
    pt14 = sprintf('   Pvalue = %6.3f',Pvalue);
    if Pvalue <= alfa
        pt15 = sprintf('   Reject Ho at significance level %.3g',alfa);
    else
        pt15 = sprintf(['   Fail to reject Ho at significance level'...
                        ' %.3g'], alfa);
    end  
    if minN <= N2
        pt17 = sprintf('   Assumes sample sizes N at least %0.f', N2);
    end
    ptref = sprintf('   Ref.: Mardia & Jupp, 2000, p. 138 (7.4.12)\n');
    disp(pt11); disp(pt12); disp(pt13); disp(pt14); disp(pt15);
    if minN <= N2; disp(pt17); end;
    disp(ptref);
    if fidO > 0
      fprintf(fidO, [pt11,'\n']);  fprintf(fidO, [pt12,'\n']); 
      fprintf(fidO, [pt13,'\n']);  fprintf(fidO, [pt14,'\n']); 
      fprintf(fidO, [pt15,'\n']);
      if minN <= N2; fprintf(fidO, [pt17,'\n']); end;
      fprintf(fidO, [ptref,'\n']); fprintf(fidO, ptskip);
    end
else
    pt111 = sprintf('   Method requires larger sample size N\n');
    disp(pt111);
    if fidO > 0; fprintf(fidO, [pt111,'\n']);  end   
end
   

