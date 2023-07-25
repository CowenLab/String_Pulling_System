function [Yr, Delta] = Vector_1way_DeltaSigma(q, DataV, ...
                                              CatN, CatTheta, PorM);     

%Vector_1way_DeltaSigma.m 

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Calculate delta and sigma values for bootstrap, assuming
% non-parametric methods. 

% Input variables:
%   q: number of samples to be analyzed
%   DataV: Array of data vectors,as in Azims
%   CatN: subsample sizes from each category, and total
%   CatTheta: Estimated vector mean for each category, plus total
%   PorM: Use P method (=0) or M method(=1)
% Output variable:
%   Yr: test statistic pre-bootstrapping
%   Delta: Vector of delta values from the P method

%Fisher, 1993, methods for non-parametric bootstrap.
% Use delta values to determine if use P or M method.
% If M, then calculate Sigma2 (sigma-squared = Delta^2/N)

%  setup / calculate some values

Delta = zeros(1,q);  
NTot = sum(CatN);
Yr = 0;

% Calculate delta values: P method (Fisher, 1993, p. 34)
% Also used to get Sigma2 values in M method
    
CC = 0;  SS = 0;  Del0 = 0;
for iii = 1:q
    
    N = CatN(iii);   Thet = CatTheta(iii)/57.3;
    bbb = 0;   ccc = 0;
    for jjj = 1:N
        aa = DataV(jjj, iii) - Thet;
        bbb = bbb + cos(2*aa);
        ccc = ccc + cos(aa);
    end
    Rbar = ccc/N;
    Delta(iii) = (1 - bbb/N)/(2*Rbar^2);
      CC = CC + N*cos(Thet);  SS = SS + N*sin(Thet);
      Del0 = Del0 + N*Delta(iii);

end

   % go back if this is preliminary calculation
   if PorM < 0;   return;   end  

Del0 = Del0/NTot;
RR = sqrt(CC^2 + SS^2);
Yr = 2*(NTot - RR)/Del0;
    
% Calculate Sigma2 values: M method  (Fisher, 1993, p. 116-117)

if PorM == 1
    
    CC = 0;  SS = 0;  SumSig = 0;
    for iii = 1:q
    
        N = CatN(iii);  Thet = CatTheta(iii)/57.3;
        Sigma2 = (Delta(iii)^2)/N;
          CC = CC + cos(Thet)/Sigma2;  
          SS = SS + sin(Thet)/Sigma2;
          SumSig = SumSig + 1/Sigma2;
    
    end

    RR = sqrt(CC^2 + SS^2);
    Yr = 2*(SumSig - RR);
    
end
        
        