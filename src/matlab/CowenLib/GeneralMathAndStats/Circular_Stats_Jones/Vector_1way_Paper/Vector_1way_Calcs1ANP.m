function RtrnCode=Vector_1way_Calcs1ANP(q, UseFrq, Azims, SummaryStats,...
                                        alfa, fidO);

%Vector_1way_Calcs1ANP.m 

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Performs the statistical tests and calculations for tests of equality
% of the vector means, assuming no (non-parametric) distribution.
% Does non-parametric version, with P vs M method, of Heterogeneous
% No bootstrap calculations here.

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
%   alfa: Level of significance: should be in range (0.001 - 0.25)
%   fidO: output file for writing calculations if fidO > 0
% Output variable:
%   RtrnCode: return code

%  setup / calculate some values

RtrnCode = 0;
[NR, NC] = size(Azims);

sumR = sum(SummaryStats(1:q, 5));
sumNRbar2 = 0;
for iii = 1:q;  
    sumNRbar2 = sumNRbar2 + SummaryStats(iii,3)*SummaryStats(iii,6)^2;   
end
MedKappa = median(SummaryStats(1:q, 8));
NTot = SummaryStats(q+1, 3);
R2 = SummaryStats(q+1, 4);  R = SummaryStats(q+1, 5);
Rbar = SummaryStats(q+1, 6);
KappaHat = SummaryStats(q+1, 8);
minN = min(SummaryStats(1:q, 3));

ptskip=sprintf('\n');
ptminus=sprintf('---------------------------------------------------\n');
ptequal=sprintf('===================================================\n');

% Test for equal vector means (theta)
% Assumes kappas are all equal, but unknown
% Assumes no distributions (non-parametric)
  
pt1A = sprintf('TEST FOR EQUALITY OF ALL q VECTOR-MEAN DIRECTIONS');
pt2A = sprintf(['Assume no distribution for data ', ...
                '(non-parametric method)']);

pt10A = sprintf('Ho: All q Vector-mean directions are equal');
disp(ptskip); disp(ptequal); disp(ptskip); disp(pt1A); disp(pt2A);
disp(ptskip); disp(pt10A); disp(ptskip);
if fidO > 0
    fprintf(fidO, ptskip); fprintf(fidO, [ptequal,'\n']); 
    fprintf(ptskip);
    fprintf(fidO, [pt1A,'\n']); fprintf(fidO, [pt2A,'\n']);
    fprintf(fidO, ptskip);  fprintf(fidO, ptskip);
    fprintf(fidO, [pt10A,'\n']); 
    fprintf(fidO, ptskip);
end  

if minN < 22
  pt111 = sprintf(['   Method require larger sample size N\n',...
                   '   Analysis not done - use Bootstrap method\n']);
  disp(pt111);
  if fidO > 0; fprintf(fidO, [pt111,'\n']);  end   
end

                  % Ref.: Fisher, 1993, p. 34, 116-117

% set up

CatN = SummaryStats(1:q, 3); CatTheta = SummaryStats(1:q, 7);
PorM = ['P'];

% determine if we will use P or M method
% calculate values for P (deltas) for entire sample
% If M, then calculate Sigma2 (sigma-squared = Delta^2/N)

Delta = zeros(1,q);  
if UseFrq > 0;  Ydata = Azims(:, q+1);  N = NR;  end;
CC = 0;  SS = 0;  Del0 = 0;  
for iii = 1:q  
    if UseFrq == 0
       Ydata = Azims(:, iii);
       N = CatN(iii);   
    end 
    Thet = CatTheta(iii)/57.3;
    bbb = 0;   ccc = 0;   NN = 0;
    for jjj = 1:N
        aa = Ydata(jjj) - Thet;
        if UseFrq == 0
           bbb = bbb + cos(2*aa);
           ccc = ccc + cos(aa);
           NN = NN + 1;
        else
           wt = Azims(jjj, iii);
           bbb = bbb + wt*cos(2*aa);
           ccc = ccc + wt*cos(aa);  
           NN = NN + wt;
        end
    end
    Rbar = ccc/NN;
    Delta(iii) = (1 - bbb/NN)/(2*Rbar^2);
      CC = CC + NN*cos(Thet);  SS = SS + NN*sin(Thet);
      Del0 = Del0 + NN*Delta(iii);
end
Del0 = Del0/NTot;
RR = sqrt(CC^2 + SS^2);
Yr = 2*(NTot - RR)/Del0;

DelRatio = max(Delta)/min(Delta);
if DelRatio >= 4   % implies M method
    
   % Calculate Sigma2 values: M method  (Fisher, 1993, p. 116-117)
    
   PorM = ['M'];
    CC = 0;  SS = 0;  SumSig = 0;
    for iii = 1:q
        N = CatN(iii);  Thet = CatTheta(iii)/57.3;
        Sigma2 = (Delta(iii)^2)/N;
          CC = CC + cos(Thet)/Sigma2; SS = SS + sin(Thet)/Sigma2;
          SumSig = SumSig + 1/Sigma2;
    end
    RR = sqrt(CC^2 + SS^2);
    Yr = 2*(SumSig - RR);
    
end
        
%Yr distributed as chi-square with (q-1) df
 df1 = q - 1;
 Pvalue = 1 - chi2cdf(Yr, df1);
 pt11 = sprintf('   Non-parametric version of heterogenity method');
 pt16 = sprintf('   Uses %s method: Delta ratio = %.1f', PorM, DelRatio);
 pt12 = sprintf(['   Under Ho, test distributed as chi-square ', ...
                 'with%3.0f d.f.'], df1);
 pt13 = sprintf('   Test statistic = %.5g', Yr);
 pt14 = sprintf('   Pvalue = %6.3f',Pvalue);
 if Pvalue <= alfa
     pt15 = sprintf('   Reject Ho at significance level %.3g',alfa);
 else
     pt15 = sprintf(['   Fail to reject Ho at significance level'...
                     ' %.3g'], alfa);
 end 
 if minN <= 27
     pt17 = sprintf('   Assumes sample sizes N at least 27');
 end
 ptref = sprintf('   Ref.: Fisher, 1993, p. 116-117,34\n');
 disp(pt11); disp(pt16); disp(pt12); disp(pt13); disp(pt14); disp(pt15); 
 if minN <= 27; disp(pt17); end;
 disp(ptref);
 if fidO > 0
   fprintf(fidO, [pt11,'\n']);  fprintf(fidO, [pt16,'\n']); 
   fprintf(fidO, [pt12,'\n']);  fprintf(fidO, [pt13,'\n']);
   fprintf(fidO, [pt14,'\n']);  fprintf(fidO, [pt15,'\n']);
   if minN <= 27; fprintf(fidO, [pt17,'\n']); end;
   fprintf(fidO, [ptref,'\n']); fprintf(fidO, ptskip);
 end

