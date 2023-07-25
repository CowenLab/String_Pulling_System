function RtrnCode = Vector_1way_Calcs2(q, SummaryStats, iii, jjj, ...
                                 IndepName, CatName, alfa, fidO);

%Vector_1way_Calcs2.m 


% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Calculate confidence interval of difference between two vector means, 
% numbered iii and jjj in Azims (also SummaryStats) array

% Input variables:
%   q: number of samples to be analyzed
%   SummaryStats: array of size q+1,8 containing calculated summary stats
%         for each of q samples and total combined sample (row q+1)
%         Columns contain:  1) sum(sines)     2) sum(cosines)     3) N
%            4) R-squared     5) R      6) R-bar    
%            7) Vector mean, theta (degrees)   8) Concentration (kappa)
%   iii, jjj: numbers of the two subsamples for the difference of their
%        vector means to be compared in conf. int. - as in Azims  
%   IndepName: identifiers of the samples
%   CatName: Array of positions in IndepName list that corresponds to 
%            columns in Azims
%   alfa: Level of significance: should be in range (0.001 - 0.25)
%   fidO: output file for writing calculations if fidO > 0
% Output variable:
%   RtrnCode: return code

% Functions and scripts called from this module:
%   CalcKappa.m
%   Vector_Stats_CDF.m

%  setup / calculate some values

RtrnCode = 0;

R1 = SummaryStats(iii, 5);  R2 = SummaryStats(jjj, 5);
NTot = SummaryStats(iii, 3) + SummaryStats(jjj, 3);

ptskip= sprintf('\n');
ptequal=sprintf('===================================================\n');
ptminus=sprintf('---------------------------------------------------\n');

% Approximate confidence interval on difference of two vector directions

% Assumes Von Mises distributions, with kappa1 = kappa2
     % Mardia, 1972, p. 165-66  (6.4.11)
     % Mardia and Jupp, 2000, p. 130-132  (7.4.16)

if iii == 1 & jjj == 2     
  pt1A = sprintf('CONFIDENCE INTERVAL ON DIFFERENCE OF TWO VECTOR MEANS');
  pt2A = sprintf('Assumes data follow Von Mises distribution');
  pt3A = sprintf('and that both Kappas (concentrations) are equal');
  ptref = sprintf('Reference: Mardia & Jupp, 2000, p. 130 - 132');
 
  disp(ptskip); disp(ptequal); disp(ptskip); disp(pt1A); disp(pt2A); 
  disp(pt3A); disp(ptref);
  if fidO > 0
    fprintf(fidO, ptskip); fprintf(fidO, [ptequal,'\n']); 
    fprintf(fidO, ptskip);
    fprintf(fidO, [pt1A,'\n']); fprintf(fidO, [pt2A,'\n']);
    fprintf(fidO, [pt3A,'\n']); fprintf(fidO, [ptref,'\n']);
    fprintf(fidO, ptskip);
  end 
end

% calculate the interval
 
diff = SummaryStats(iii, 7) - SummaryStats(jjj, 7);
if diff > 180;  diff = diff - 360; end;
if diff < -180; diff = diff + 360; end;

KapHat = CalcKappa((R1 + R2)/NTot, 0);
P1 = KapHat*R1;  P2 = KapHat*R2;
A1 = CalcKappa(P1, 1);
A2 = CalcKappa(P2, 1);
KappaStar = CalcKappa(A1*A2, 0);

Az = linspace(0, 180, 361);
CDF = Vector_Stats_CDF(Az/57.3, 0, KappaStar);
find = 0.5 - alfa/2;
delta = interp1(CDF, Az, find, 'cubic');

CI1 = diff - delta;
if CI1 > 180;  CI1 = CI1 - 360; end
if CI1 < -180; CI1 = CI1 + 360; end;
CI2 = diff + delta;
if CI1 > 180;  CI1 = CI1 - 360; end
if CI1 < -180; CI1 = CI1 + 360; end;

% output 

Categ1 = mat2str(IndepName(CatName(iii),:));  
Categ2 = mat2str(IndepName(CatName(jjj),:));
pt11 = sprintf(['   Interval on difference of vector means for', ...
                ' identifiers %s - %s'], Categ1, Categ2);
pt12 = sprintf('   Difference = %.1f degrees ', diff);  
pt13 = sprintf('   Confidence level = %.4f', 1 - alfa);
pt14 = sprintf('   Confidence interval: Arc over (%.1f, %.1f) degrees',...
               CI1, CI2);
pt15 = sprintf(['   Interval defined in clockwise direction,\n' ...
                '      centered on observed difference of vector means']);
disp(ptskip); disp(pt11); disp(pt12); disp(pt13); disp(pt14); 
disp(pt15); 
if fidO > 0
  fprintf(fidO, ptskip);
  fprintf(fidO, [pt11,'\n']); 
  fprintf(fidO, [pt12,'\n']);  fprintf(fidO, [pt13,'\n']);
  fprintf(fidO, [pt14,'\n']);  fprintf(fidO, [pt15,'\n']);
end 


clear Az CDF

