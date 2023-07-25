function RtrnCode = Vector_1way_Calcs3A(q, UseFrq, Azims, SummaryStats, ...
                                        CalcsToDo, Nlimit2, ...
                                        alfa, fidO);

%Vector_1way_Calcs3A.m 

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Performs the statistical tests for the equality of all Kappas.
% Does the tests: 1) Small Rbar,  2) Intermediate Rbar,
%                 3) High Rbar (large Kappas), 4) Tangential method 
% This does not use bootstrap methods.

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
MedKappa = median(SummaryStats(1:q, 8));
NTot = SummaryStats(q+1, 3);
CatN = SummaryStats(:, 3);
CatTheta = SummaryStats(:, 7);
minN = min(CatN(1:q));

ptskip= sprintf('\n');
ptequal=sprintf('===================================================\n');
ptminus=sprintf('---------------------------------------------------\n');

% Test for equal concentrations (kappa)
% No constraints on vector means
% Assumes Von Mises distributions

pt1A = sprintf('TEST FOR EQUALITY OF ALL q CONCENTRATIONS KAPPA');
pt2A = sprintf('Assume data follow Von Mises distribution');

pt10A = sprintf('Ho: All q Kappa (concentrations) are equal');
 
disp(ptskip); disp(ptequal); disp(ptskip); disp(pt1A); disp(pt2A);
disp(ptskip); disp(pt10A); disp(ptskip);
if fidO > 0
    fprintf(fidO, ptskip); fprintf(fidO, [ptequal,'\n']); 
    fprintf(fidO, ptskip);
    fprintf(fidO, [pt1A,'\n']); fprintf(fidO, [pt2A,'\n']);
    fprintf(fidO, ptskip);
    fprintf(fidO, [pt10A,'\n']); 
    fprintf(fidO, ptskip);
end 

          % Rbar < 0.45   
          % Mardia, 1972, p. 165-66  (6.4.11)
          % Mardia and Jupp, 2000, p. 140  (7.4.23)
          
if CalcsToDo(1) > 0
    www = 0; U11 = 0; U12 = 0;
    for iii = 1:q
         Rtilde = 2*SummaryStats(iii, 6);
         g1 = asin(0.61237*Rtilde);
         w = 1.3333*(SummaryStats(iii, 3) - 4);
         www = www + w;
         U11 = U11 + w*g1^2;
         U12 = U12 + w*g1;
     end
     test = U11 - U12*U12/www;
     %distributed as chi-square with q-1 df
    df1 = q - 1;
    Pvalue = 1 - chi2cdf(test, df1);
    pt11 = sprintf('   Kappa < 1 (Rbar < 0.45)');
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
    ptref = sprintf('   Ref.: Mardia & Jupp, 2000, p. 140 (7.4.23)\n');
    disp(ptskip); disp(pt11); disp(pt12); disp(pt13); disp(pt14); 
    disp(pt15); 
    if minN <= Nlimit2(1); disp(pt17); end;
    disp(ptref);
    if fidO > 0
      fprintf(fidO, ptskip);
      fprintf(fidO, [pt11,'\n']); 
      fprintf(fidO, [pt12,'\n']);  fprintf(fidO, [pt13,'\n']);
      fprintf(fidO, [pt14,'\n']);  fprintf(fidO, [pt15,'\n']);
      if minN <= Nlimit2(1); fprintf(fidO, [pt17,'\n']); end;
      fprintf(fidO, [ptref,'\n']);
    end 
end
                    
          % 0.45 <= Rbar <= 0.7   and    0.9 < Kappa <= 2
          % Mardia, 1972, p. 166, (6.4.12)
          % Mardia and Jupp, 2000, p. 140 (7.4.24)
          % Running test for Rbar > .40 because
          %    other test above not good at Kappa=1 (Rbar=0.45)
          
if CalcsToDo(2) > 0          
    www = 0; U11 = 0; U12 = 0;
    for iii = 1:q
         g2 = asinh((SummaryStats(iii, 6)-1.08940)/0.25789);
         w = (SummaryStats(iii, 3) - 3)/0.7979;
         www = www + w;
         U11 = U11 + w*g2^2;
         U12 = U12 + w*g2;
     end
     test = U11 - U12*U12/www;          
     % distributed as chi-square with q-1 df
    df1 = q - 1;
    Pvalue = 1 - chi2cdf(test, df1);
    pt11 = sprintf('   1 < Kappa < 2 (0.45 < Rbar < 0.70)');
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
    if minN <= Nlimit2(2)
        pt17 = sprintf('   Assumes sample sizes N at least %0.f', ...
                       Nlimit2(2));
    end
    ptref = sprintf('   Ref.: Mardia & Jupp, 2000, p. 140 (7.4.24)\n');
    disp(ptskip); disp(pt11); disp(pt12); disp(pt13); disp(pt14); 
    disp(pt15); 
    if minN <= Nlimit2(2); disp(pt17); end;
    disp(ptref);
    if fidO > 0
      fprintf(fidO, ptskip);
      fprintf(fidO, [pt11,'\n']); 
      fprintf(fidO, [pt12,'\n']);  fprintf(fidO, [pt13,'\n']);
      fprintf(fidO, [pt14,'\n']);  fprintf(fidO, [pt15,'\n']);
      if minN <= Nlimit2(2); fprintf(fidO, [pt17,'\n']); end;
      fprintf(fidO, [ptref,'\n']);
    end 
end
          
          % Rbar > 0.7  (Kappa > 2) (high-concentration approximation)
          % Mardia, p.166, 1972 (6.4.13)
          % Mardia and Jupp, 2000, p. 140  (7.4.25)
          
if CalcsToDo(3) > 0
    N = NTot;
    df1 = q - 1;
    UUU = (N - q)*log((N - sumR)/(N - q));
    VVV = 0; DDD = 0;
    for iii = 1:q
        nnn = SummaryStats(iii, 3) - 1;
        VVV = VVV + nnn*log((nnn + 1 - SummaryStats(iii,5))/nnn);
        DDD = DDD + 1/nnn;
    end
    DDD = DDD - 1/(N - q); DDD = DDD/(3*df1);
    test = (UUU - VVV)/(1 + DDD);
    %distributed as chi-square with q-1 df
    Pvalue = 1 - chi2cdf(test, df1); 
    pt11 = sprintf('   Kappa > 2 (Rbar > 0.70)');
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
    if minN <= Nlimit2(3)
        pt17 = sprintf('   Assumes sample sizes N at least %0.f', ...
                       Nlimit2(3));
    end
    ptref = sprintf('   Ref.: Mardia & Jupp, 2000, p. 140 (7.4.25)\n');
    disp(ptskip); disp(pt11); disp(pt12); disp(pt13); disp(pt14); 
    disp(pt15); 
    if minN <= Nlimit2(3); disp(pt17); end;
    disp(ptref); 
    if fidO > 0
      fprintf(fidO, ptskip);
      fprintf(fidO, [pt11,'\n']); 
      fprintf(fidO, [pt12,'\n']);  fprintf(fidO, [pt13,'\n']);
      fprintf(fidO, [pt14,'\n']);  fprintf(fidO, [pt15,'\n']);
      if minN <= Nlimit2(3); fprintf(fidO, [pt17,'\n']); end;
      fprintf(fidO, [ptref,'\n']);
    end 
end
       
% -----------------------------------------------------------------

             %Tangential method - robust to outliers and non-Mises
             % Large sample
             % Fisher, 1993, p. 131
             % Mardia and Jupp, 2000, p. 139 (7.4.17)
  
if CalcsToDo(4) > 0            
 % get sums for calcs  
 df1 = q - 1;  df2 = NTot - q;
 Dsum = zeros(q, 1);  Dsum2 = zeros(q, 1);
 DBar = zeros(q, 1);  DBarbar = 0;
 [NRR, NCC] = size(Azims);
 for iii = 1:q;
     N = CatN(iii);  Thet = CatTheta(iii)/57.3;
     if UseFrq == 0; MM = N; else; MM = NRR; end;
     for jjj = 1:MM;
         if UseFrq == 0
             D = abs(sin(Azims(jjj, iii) - Thet)); 
             Dsum(iii) = Dsum(iii) + D;  Dsum2(iii) = Dsum2(iii) + D*D; 
         else
             Az = Azims(jjj, q+1);   wt = Azims(jjj, iii);
             D = abs(sin(Az - Thet));
             Dsum(iii) = Dsum(iii) + wt*D;  
             Dsum2(iii) = Dsum2(iii) + wt*D*D; 
         end
     end
     DBar(iii) = Dsum(iii);
     DBarbar = DBarbar + DBar(iii);
     DBar(iii) = DBar(iii)/N;    
 end
 DBarbar = DBarbar/NTot;
  
 % calc test statistic
 UUU = 0;   VVV = 0;
 for iii = 1:q
     UUU = UUU + CatN(iii)*(DBar(iii) - DBarbar)^2;
     VVV = VVV + Dsum2(iii) - Dsum(iii)*DBar(iii);
 end
 test = df2*UUU/(df1*VVV);
  %distributed as F with q-1, N-q df
  Pvalue = 1 - fcdf(test, df1, df2); 
  pt11 = sprintf('   Tangential method');
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
  if minN <= Nlimit2(4)
        pt17 = sprintf('   Assumes sample sizes N at least %0.f', ...
                       Nlimit2(4));
    end
  ptref = sprintf(['   Ref.: Mardia & Jupp, 2000, p. 139 \n', ...
                   '         Fisher, 1993, p. 131-132']);
  disp(ptskip); disp(pt11); disp(pt12); disp(pt13); disp(pt14); 
  disp(pt15);  
  if minN <= Nlimit2(4); disp(pt17); end;
  disp(ptref);
  if fidO > 0
      fprintf(fidO, ptskip);
      fprintf(fidO, [pt11,'\n']); 
      fprintf(fidO, [pt12,'\n']);  fprintf(fidO, [pt13,'\n']);
      fprintf(fidO, [pt14,'\n']);  fprintf(fidO, [pt15,'\n']);
      if minN <= Nlimit2(4); fprintf(fidO, [pt17,'\n']); end;
      fprintf(fidO, [ptref,'\n']);
  end 
end

if sum(CalcsToDo(1:4)) == 0
  pt111 = sprintf(['   Methods require larger Kappa or N\n',...
                   '   Analysis not done - use Randomization/', ...
                   'Resampling method\n']);
  disp(pt111);
  if fidO > 0; fprintf(fidO, [pt111,'\n']);  end   
end


