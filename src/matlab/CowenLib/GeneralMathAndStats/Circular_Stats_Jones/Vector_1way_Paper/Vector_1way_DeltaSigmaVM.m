function Yr = Vector_1way_DeltaSigmaVM(q, ...
                                  CatN, CatRbar, CatTheta, CatKappa);     

%Vector_1way_DeltaSigmaVM.m 

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Calculate delta and sigma values for bootstrap uassuming vonMises. 

% Input variables:
%   q: number of samples to be analyzed
%   CatN: subsample sizes from each category, and total
%   CatRbar: Rbar values for each category, and total
%   CatTheta: Estimated vector mean for each category, plus total
%   CatKappa: concentration Kappa for each category, plus total
% Output variable:
%   Yr: test statistic pre-bootstrapping

%Fisher, 1993, methods for bootstrap under Von Mises distribution.

%  setup / calculate some values
  
NTot = sum(CatN);
Yr = 0;

% Calculate Sigma2 values in M method, and hence test statistic Yr
% (Fisher, 1993, p. 124)
    
SnRK = 0;  CC = 0;  SS = 0;  
for iii = 1:q
    
    N = CatN(iii);  Thet = CatTheta(iii)/57.3;
    nRK = N*CatRbar(iii)*CatKappa(iii);
    SnRK = SnRK + nRK;
    Sigma2 = 1/nRK;
    CC = CC + cos(Thet)/Sigma2;  
    SS = SS + sin(Thet)/Sigma2;
    
end

RR = sqrt(CC^2 + SS^2);
Yr = 2*(SnRK - RR);
    
        
        