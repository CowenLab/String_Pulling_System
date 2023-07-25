function [YrTot, TestCut, Pvalue] = Vector_1way_Bootstrap_TestMeansVM( ...
                                 q, CatN, CatRbar, CatTheta, CatKappa, ...
                                 NB, alfa)

%Vector_1way_Bootstrap_TestMeansVM.m

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Generate test of hypothesis on equality of vector means using 
% resampling (bootstrapping) methods.
% Assumes Von Mises distribution

% Input variables:
%   q: number of samples to be analyzed
%   CatN: subsample sizes from each category, and total
%   CatRbar: Rbar values for each category, and total
%   CatTheta: Estimated vector mean for each category, plus total
%   CatKappa: concentration Kappa for each category, plus total
%   NB: number of bootstrap iterations
%   alfa: Level of significance: should be in range (0.001 - 0.25)
% Output variable:
%   YrTot: test statistic pre-bootstrapping
%   TestCut: cutoff for testing developed via bootstrap
%   Pvalue: p-value of the test using test statistic

% Functions and scripts called from this module:
%   Vector_1way_DeltaSigmaVM.m
%   VonMises_GenerateRandomRad.m
%   VectMean_arctan.m
%   CalcKappa.m

% Ref.: Fisher, 1993, p. 124-125, 199-207, 213-214

% set up

CatReRbar = CatRbar;  CatReTheta = CatTheta;  CatReKappa = CatKappa;

 % test value calculated for original sample
    
Yr = Vector_1way_DeltaSigmaVM(q, CatN, CatRbar, CatTheta, CatKappa);
YrTot = Yr;

% loop over NB iterations

BStraps = zeros(NB,1);

for ijk = 1:NB
    
    % generate random Von Mises sample for each category
    % and calculate critical statistics
    
  for iii = 1:q
      
    NNN = CatN(iii);  
    Kap = CatKappa(iii);  
    RandVals = VonMises_GenerateRandomRad(NNN, 0, Kap);
    
    % calculate estimates from this sample
    
    SS = sum(sin(RandVals));
    CC = sum(cos(RandVals));   
    CatReTheta(iii) = VectMean_arctan(SS, CC);
    Rbar = sqrt(SS^2 + CC^2)/NNN;
    CatReRbar(iii) = Rbar;
    CatReKappa(iii) = CalcKappa(Rbar, 0);
  
  end  
      
  % calculate test statistic for this resampling
  
  Yr = Vector_1way_DeltaSigmaVM(q, CatN, CatReRbar,CatReTheta, CatReKappa);
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

clear BStraps Sgamma Pgamma RandVals CatReTheta CatReKappa CatReRbar 
  