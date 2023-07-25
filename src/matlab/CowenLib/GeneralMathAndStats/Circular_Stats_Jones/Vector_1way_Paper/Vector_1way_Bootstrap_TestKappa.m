function [frTot, TestCut, Pvalue] = ...
                          Vector_Stats_Bootstrap_TestKappa(q, UseFrq, ...
                                        Azims, CatN, CatTheta, NB, alfa)

%Vector_1way_Bootstrap_TestKappa.m

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Performs the statistical tests required with the bootstrapping
% (resampling) method for Kappas.
% Assumes nothing about distributions.

% Input variables:
%   q: number of samples to be analyzed
%   UseFrq: 0 = data input as individual azimuths
%           1 = data input as azimuth column, plus q columns of counts
%   Azims: Array of azimuths to be processed, in radians
%   CatN: sample sizes for each subsample, plut total sample size
%   CatTheta: vector mean (degr) for each subsample, plus total sample
%   NB: number of bootstrap iterations
%   alfa: Level of significance: should be in range (0.001 - 0.25)
% Output variable:
%   frTot: test statistics, pre-resampling
%   TestCut: cutoff value for testing, at required alfa
%   Pvalue: p-value of the test, using frTot

% Functions and scripts called from this module:
%   Vector_1way_SetupBoot_TestKappa.m  
%   Vector_1way_fr.m
%   VectMean_arctan.m

% Ref.: Fisher, 1993, p. 115-117, 199-207, 213-214

% set up

NTot = CatN(q+1);

% gather data for single array

[Yvect, NcntL, NcntH] = Vector_1way_SetupBoot_TestKappa(q, ...
                                         UseFrq, Azims, CatN);
                                     
% value calculated for original sample

fr = Vector_1way_fr(q, Yvect, NcntL, NcntH, CatTheta);
frTot = fr;

% center the observations in prep for resampling

for iii = 1:q
    Thet = CatTheta(iii)/57.3;
    N1 = NcntL(iii); N2 = NcntH(iii);
    Yvect(N1:N2) = Yvect(N1:N2) - Thet;
end

% loop over NBB = NB iterations

phi = zeros(size(Yvect));
   %NBB = 2*NB;
NBB = NB;
BStraps = zeros(NBB,1);

for ijk = 1:NBB
    
    % generate random resample for entire sample
    
    RN = randperm(NTot);
    for jjj = 1:NTot
        phi(jjj) = Yvect(RN(jjj));
    end
 
    % calculate estimates from this resample
    
    for iii = 1:q
        N1 = NcntL(iii);   N2 = NcntH(iii);
        SS = sum(sin(phi(N1:N2)));   CC = sum(cos(phi(N1:N2)));   
        CatReTheta(iii) = VectMean_arctan(SS, CC);
    end
      
    % calculate test statistic for this resampling
  
    fr = Vector_1way_fr(q, phi, NcntL, NcntH, CatReTheta);
    BStraps(ijk) = fr;
    
end

% calculate test cutoff and P-value

Sgamma = sort(BStraps);
Pgamma = linspace(1., 0., NBB);   

TestCut = interp1(Pgamma, Sgamma, alfa);
if frTot <= Sgamma(1);   Pvalue = 1;
else  if frTot >= Sgamma(NBB);    Pvalue = 0;
      else
        Pvalue = interp1(Sgamma, Pgamma, frTot);
      end
end

clear phi RN BStraps Sgamma Pgamma Yvect CatReTheta 
  