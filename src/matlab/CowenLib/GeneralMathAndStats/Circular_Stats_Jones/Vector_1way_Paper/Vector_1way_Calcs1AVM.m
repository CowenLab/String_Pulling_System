function RtrnCode = Vector_1way_Calcs1AVM(q, SummaryStats, CalcsToDo, ...
                                          Nlimit2, alfa, fidO);

%Vector_1way_Calcs1AVM.m

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
%          5) Heterogeneous   
% No bootstrap calculations here.

% Input variables:
%   q: number of samples to be analyzed
%   SummaryStats: array of size q+1,8 containing calculated summary stats
%         for each of q samples and total combined sample (row q+1)
%         Columns contain:  1) sum(sines)     2) sum(cosines)     3) N
%            4) R-squared     5) R      6) R-bar    
%            7) Vector mean, theta (degrees)   8) Concentration (kappa)
%   CalcsToDo: Do each individual test for corresp. entries in array?
%              yes = 1; 0 = no
%   Nlimit2: do bootstrap if all subsample sizes less than this
%   alfa: Level of significance: should be in range (0.001 - 0.25)
%   fidO: output file for writing calculations if fidO > 0
% Output variable:
%   RtrnCode: return code

%  setup / calculate some values

RtrnCode = 0;
sumR = sum(SummaryStats(1:q, 5));
sumNRbar2 = 0;
for iii = 1:q;  
    sumNRbar2 = sumNRbar2 + SummaryStats(iii,3)*SummaryStats(iii,6)^2;   
end
MedKappa = median(SummaryStats(1:q, 8));
N = SummaryStats(q+1, 3);
R2 = SummaryStats(q+1, 4);  R = SummaryStats(q+1, 5);
Rbar = SummaryStats(q+1, 6);
KappaHat = SummaryStats(q+1, 8);
minN = min(SummaryStats(1:q, 3));

ptskip=sprintf('\n');
ptminus=sprintf('---------------------------------------------------\n');
ptequal=sprintf('===================================================\n');

% Test for equal vector means (theta)
% Assumes kappas are all equal, but unknown
% Assumes Von Mises distributions

pt1A = sprintf('TEST FOR EQUALITY OF ALL q VECTOR-MEAN DIRECTIONS');
pt2A = sprintf('Assume data follow Von Mises distribution');

pt10A = sprintf('Ho: All q Vector-mean directions are equal');
pt10B = sprintf(['Assumption: All Kappas (concentrations) are equal, ', ...
                 'but unknown']);
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

          % kappa < 1 ; Rbar < 0.45  but kappa not near 0 
          % (Based on likelihood ratio test, assuming Von Mises)
          % Mardia, 1972, p. 164 (6.4.6)
          % Mardia and Jupp, 2000, p. 137 (7.4.11)
          
if CalcsToDo(1) > 0
    ccc = 1/(1 - 0.125*KappaHat^2 + q/(2*N*KappaHat^2));
    UUU = 2*(sumR^2 - R2)/N;
    test = ccc*UUU;
    %distributed as chi-square with q-1 df
    df1 = q - 1;
    Pvalue = 1 - chi2cdf(test, df1);
    pt11 = sprintf(['   Kappa < 1 (Rbar < 0.45) and ', ...
                    'Kappa > 0.05 (Rbar > 0.025)']);
    pt12 = sprintf(['   Under Ho, test distributed as chi-square ', ...
                    'with%3.0f d.f.'], df1);
    pt13 = sprintf('   Test statistic = %.5g', test);
    pt14 = sprintf('   Pvalue = %6.3f',Pvalue);
    if Pvalue <= alfa
        pt15 = sprintf('   Reject Ho at significance level %.3g', ...
                       alfa);
    else
        pt15 = sprintf(['   Fail to reject Ho at significance level'...
                        ' %.3g'], alfa);
    end
    if minN <= Nlimit2(1)
        pt17 = sprintf('   Assumes sample sizes N at least %0.f', ...
                       Nlimit2(1));
    end
    ptref = sprintf('   Ref.: Mardia & Jupp, 2000, p. 137, (7.4.11)\n');
    disp(pt11); disp(pt12); disp(pt13); disp(pt14); disp(pt15);
    if minN <= Nlimit2(1); disp(pt17); end;
    disp(ptref);
    if fidO > 0
      fprintf(fidO, [pt11,'\n']);  fprintf(fidO, [pt12,'\n']); 
      fprintf(fidO, [pt13,'\n']);  fprintf(fidO, [pt14,'\n']); 
      fprintf(fidO, [pt15,'\n']);
      if minN <= Nlimit2(1); fprintf(fidO, [pt17,'\n']); end;
      fprintf(fidO, [ptref,'\n']); fprintf(fidO, ptskip);
    end
end
          
          % kappa >= 1 ; Rbar >= 0.45  (Multi-sample Watson-Williams test)
          % Mardia, 1972, p. 163 (6.4.4)
          % Mardia and Jupp, 2000, p. 135 (7.4.6)
          % Fisher, 1993, p. 126-127   (suggests Kappa > 2 to apply)
          % Running test for Rbar > .40 because
          %    other test above not good at Kappa=1 (Rbar=0.45)
          
if CalcsToDo(2) > 0          
    df1 = q - 1;   df2 = N - q;
    UUU = df2*(sumR - R);
    VVV = (N - sumR)*df1;
    test = UUU/VVV;
    if CalcsToDo(2) == 2      % adjust for Fisher b1 case, p. 127
      test = (1 + 3/(8*MedKappa))*test;
    end
    %distributed as F with (q-1, N-q) df 
    Pvalue = 1 - fcdf(test, df1, df2);
    pt11 = sprintf('   Kappa > 1 (Rbar > 0.40)');
    pt12 = sprintf(['   Under Ho, test distributed as F ', ...
                    'with%3.0f,%5.0f d.f.'], df1, df2);
    pt13 = sprintf('   Test statistic = %.5g', test);
    pt14 = sprintf('   Pvalue = %6.3f',Pvalue);
    if Pvalue <= alfa
        pt15 = sprintf('   Reject Ho at significance level %.3g', ...
                       alfa);
    else
        pt15 = sprintf(['   Fail to reject Ho at significance level'...
                        ' %.3g'], alfa);
    end
    if minN <= Nlimit2(2)
        pt17 = sprintf('   Assumes sample sizes N at least %0.f', ...
                       Nlimit2(2));
    end
    ptref = sprintf(['   Ref.: Mardia & Jupp, 2000, p. 135 (7.4.6)\n',...
                     '         Fisher, 1993, p. 126-127\n']);
    disp(pt11); disp(pt12); disp(pt13); disp(pt14); disp(pt15);
    if minN <= Nlimit2(2); disp(pt17); end;
    disp(ptref);
    if fidO > 0
      fprintf(fidO, [pt11,'\n']);  fprintf(fidO, [pt12,'\n']); 
      fprintf(fidO, [pt13,'\n']);  fprintf(fidO, [pt14,'\n']); 
      fprintf(fidO, [pt15,'\n']);
      if minN <= Nlimit2(2); fprintf(fidO, [pt17,'\n']); end;
      fprintf(fidO, [ptref,'\n']); fprintf(fidO, ptskip);
    end
end
  
             % Embedding method
             % Large kappas required
             % Mardia and Jupp, 2000, p. 139 (7.4.16)
             % Harrison, Kanji, and Gadsen, 1986, p. 135-136
        
if CalcsToDo(3) > 0             
    df1 = q - 1;   df2 = N - q;
    ccc = 1 - 1/(5*KappaHat) - 1/(10*KappaHat^2);
    UUU = (sumNRbar2 - N*Rbar^2)/df1;
    VVV = (N - sumNRbar2)/df2;
    test = ccc*UUU/VVV;
    %distributed as F with (q-1, N-q) df 
    Pvalue = 1 - fcdf(test, df1, df2);
    pt11 = sprintf('   Embedding method for Large Kappas');
    pt12 = sprintf(['   Under Ho, test distributed as F ', ...
                    'with%3.0f,%5.0f d.f.'], df1, df2);
    pt13 = sprintf('   Test statistic = %.5g', test);
    pt14 = sprintf('   Pvalue = %6.3f',Pvalue);
    if Pvalue <= alfa
        pt15 = sprintf('   Reject Ho at significance level %.3g', ...
                       alfa);
    else
        pt15 = sprintf(['   Fail to reject Ho at significance level'...
                        ' %.3g'], alfa);
    end  
    if minN <= Nlimit2(3)
        pt17 = sprintf('   Assumes sample sizes N at least %0.f', ...
                       Nlimit2(3));
    end
    ptref = sprintf(['   Ref.: Mardia & Jupp, 2000, p. 139 (7.4.16)\n',...
                     '         Harrison et al, 1986, p. 135-136\n']);
    disp(pt11); disp(pt12); disp(pt13); disp(pt14); disp(pt15);
    if minN <= Nlimit2(3); disp(pt17); end;
    disp(ptref);
    if fidO > 0
      fprintf(fidO, [pt11,'\n']);  fprintf(fidO, [pt12,'\n']); 
      fprintf(fidO, [pt13,'\n']);  fprintf(fidO, [pt14,'\n']); 
      fprintf(fidO, [pt15,'\n']);
      if minN <= Nlimit2(3); fprintf(fidO, [pt17,'\n']); end;
      fprintf(fidO, [ptref,'\n']); fprintf(fidO, ptskip);
    end 
end   
         
if sum(CalcsToDo(1:3)) == 0
  pt111 = sprintf(['   Possible methods require larger Kappa or N\n',...
                   '   Analysis not done - use Bootstrap method\n']);
  disp(pt111);
  if fidO > 0; fprintf(fidO, [pt111,'\n']);  end   
end

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -              

           % Heterogeneous case - Test for equal Thetas, but not assume 
           %                      all concentrations Kappa are equal
           %            Requires large sample sizes
           %            Mardia and Jupp, 2000, p. 141-2 (7.4.28)
           %            Fisher, 1993, p. 124-125, 117 
 
  pt10A = sprintf('Ho: All q Vector-mean directions are equal');
  pt10B = sprintf(['Assumption: Kappas (concentrations) are unequal',...
                   ' and unknown\n']);
  disp(ptskip); disp(ptminus); disp(ptskip); disp(pt10A);  
  disp(pt10B);  disp(ptskip);
  if fidO > 0
    fprintf(fidO, ptskip); fprintf(fidO, ptminus);  
    fprintf(fidO, ptskip);
    fprintf(fidO, [pt10A,'\n']); fprintf(fidO, [pt10B,'\n']); 
    fprintf(fidO, ptskip);
  end            
           
if CalcsToDo(5) > 0  
     sumKR = 0;  sumKRcos = 0;  sumKRsin = 0;
    for iii = 1:q
        KR = SummaryStats(iii, 8)*SummaryStats(iii, 5);  
        CT = SummaryStats(iii, 7)/57.3;
        sumKR = sumKR + KR;  
        sumKRcos = sumKRcos + KR*cos(CT);  
        sumKRsin = sumKRsin + KR*sin(CT);
    end
    RW = sqrt(sumKRcos^2 + sumKRsin^2);
    test = 2*(sumKR - RW);
    %distributed as chi-square with q-1 df
    df1 = q - 1;
    Pvalue = 1 - chi2cdf(test, df1);
    pt11 = sprintf('   Heterogeneous case - requires large sample size');
    pt12 = sprintf(['   Under Ho, test distributed as chi-square ', ...
                    'with%3.0f d.f.'], df1);
    pt13 = sprintf('   Test statistic = %.5g', test);
    pt14 = sprintf('   Pvalue = %6.3f',Pvalue);
    if Pvalue <= alfa
        pt15 = sprintf('   Reject Ho at significance level %.3g', alfa);
    else
        pt15 = sprintf(['   Fail to reject Ho at significance level'...
                        ' %.3g'], alfa);
    end   
    if minN <= Nlimit2(5)
        pt17 = sprintf('   Assumes sample sizes N at least %0.f', ...
                       Nlimit2(5));
    end
    ptref = sprintf(['   Ref.: Mardia & Jupp, 2000, p. 141-142\n',...
                     '         Fisher, 1993, p. 124-125, 117\n']);
    disp(pt11); disp(pt12); disp(pt13); disp(pt14); disp(pt15);
    if minN <= Nlimit2(5); disp(pt17); end;
    disp(ptref);
    if fidO > 0
      fprintf(fidO, [pt11,'\n']);  fprintf(fidO, [pt12,'\n']); 
      fprintf(fidO, [pt13,'\n']);  fprintf(fidO, [pt14,'\n']); 
      fprintf(fidO, [pt15,'\n']);
      if minN <= Nlimit2(5); fprintf(fidO, [pt17,'\n']); end;
      fprintf(fidO, [ptref,'\n']); fprintf(fidO, ptskip);
    end
else
    pt111 = sprintf(['   Heterogeneous method requires all Kappa > 1.7\n',...
                    '   Analysis not done - use von Mises resampling\n']);
    disp(pt111);
    if fidO > 0;  fprintf(fidO, [pt111,'\n']);  end;
end
    
