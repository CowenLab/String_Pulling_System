function [YrTot, TestCut, Pvalue, DelRatio] = ...
                          Vector_Stats_Bootstrap_TestMeans(q, UseFrq, ...
                                        Azims, CatN, CatTheta, NB, alfa)

%Vector_1way_Bootstrap_TestMeans.m

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Generate test of hypothesis on equality of vector means using 
% resampling (bootstrapping) methods.
% Assumes no distribution distribution and non-equal kappas

% Input variables:
%   q: number of samples to be analyzed
%   UseFrq: 0 = data input as individual azimuths
%           1 = data input as azimuth column, plus q columns of counts
%   Azims: Array of azimuths to be processed, in radians
%   CatN: subsample sizes from each category, and total
%   CatTheta: Estimated vector mean for each category, plus total
%   NB: number of bootstrap iterations
%   alfa: Level of significance: should be in range (0.001 - 0.25)
% Output variable:
%   YrTot: test statistic pre-bootstrapping
%   TestCut: cutoff for testing developed via bootstrap
%   Pvalue: p-value of the test using test statistic
%   DelRatio: ratio of largest to smallest delta value (P method)

% Functions and scripts called from this module:
%   Vector_1way_DeltaSigma.m
%   VectCnt2IndivAz.m
%   VectMean_arctan.m

% Ref.: Fisher, 1993, p. 115-117, 199-207, 213-214

% set up

CatReTheta = CatTheta;  NT = max(CatN(1:q));

%get data for initial calcs, make copy in case of UseFrq>0
if UseFrq == 0
    Ydata = Azims;
else
    Ydata = zeros(NT, q); 
    for iii = 1:q
      Result = VectCnt2IndivAz(Azims, iii, 1);   
      LR = length(Result);
      Ydata(1:LR, iii) = Result(1:LR); 
    end
end

% determine if we will use P or M method
% also, calculate algorithm values for entire sample

   % preliminary calc
[Yr, Delta] = Vector_1way_DeltaSigma(q, Ydata, CatN, CatTheta, -1);

DelRatio = max(Delta)/min(Delta);
if DelRatio <= 4
    PorM = 0;    %0 implies P method
else
    PorM = 1;    %1 implies M method
end

    % value calculated for original sample
[Yr, Delta] = Vector_1way_DeltaSigma(q, Ydata, CatN, CatTheta, PorM);
YrTot = Yr;

% center the observations in prep for resampling

for iii = 1:q
    Ydata(:,iii) = Ydata(:,iii) - CatTheta(iii)/57.3;
end

% loop over NB iterations

phi = Ydata;
RN = zeros(max(CatN),1);
BStraps = zeros(NB,1);

for ijk = 1:NB
    
    % generate random resample for each category sample
    
  for iii = 1:q
      
    NNN = CatN(iii);  
    
    RN = rand(NNN,1);
    RNi = fix(NNN*RN + 1);
    for jjj = 1:NNN
        phi(jjj, iii) = Ydata(RNi(jjj), iii);
    end
    
    % calculate estimate from this resample
    
    SS = 0;  CC = 0;  
    for jjj = 1:NNN
        SS = SS + sin(phi(jjj, iii));
        CC = CC + cos(phi(jjj, iii));   
    end
    CatReTheta(iii) = VectMean_arctan(SS, CC);
  
  end  
      
  % calculate test statistic for this resampling
  
  [Yr, Delta] = Vector_1way_DeltaSigma(q, phi, CatN, CatReTheta, PorM);
  BStraps(ijk) = Yr;
    
end

% calculate test cutoff and P-value

Sgamma = sort(BStraps);
Pgamma = linspace(1., 0., NB);   

TestCut = interp1(Pgamma, Sgamma, alfa);
if YrTot <= Sgamma(1);   Pvalue = 1;
else  if YrTot >=Sgamma(NB);    Pvalue = 0;
      else
        Pvalue = interp1(Sgamma, Pgamma, YrTot);
      end
end

clear phi RN RNi BStraps Sgamma Pgamma Ydata CatReTheta Result
  