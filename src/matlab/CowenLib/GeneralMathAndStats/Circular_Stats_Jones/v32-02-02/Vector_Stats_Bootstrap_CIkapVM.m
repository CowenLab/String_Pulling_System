function [K1, K2] = Vector_Stats_Bootstrap_CIkapVM(Ydata, ...
                                B, N, ThetaBarR, KappaHat, alfa)

%Vector_Stats_Bootstrap_CIkapVM.m

% Generate confidence interval on concentration parameter of vonMises
%   using resampling (bootstrapping) methods.

% Input variables:
%   Ydata: azimuth data (radians)
%   B: number of bootstrapping iterations
%   N: sample size
%   ThetaBarR: calculated vector mean (radians)
%   KappaHat: calculated kappa estimate
%   alfa: significance level
% Output variables:
%   K1, K2:  limits of confidence interval on concentration kappa

% Called functions:
%   Vector_Stats_Bootstrap_Algor.m
%   VonMises_GenerateRandomRad.m
%   CalcKappa.m

% Ref.: Fisher, 1993, p. 90-91, 199-207, 210-211

% calculate algorithm values for entire sample

[Z0, V0, W0] = Vector_Stats_Bootstrap_Algor(Ydata);

% loop over B iterations

phi = zeros(N,1);
BStraps = zeros(B,1);

for iii = 1:B
    
    % generate random resample
    
    phi = VonMises_GenerateRandomRad(N, ThetaBarR, KappaHat);
%    cc=sum(cos(phi))/N;ss=sum(sin(phi))/N;ss=sqrt(cc*cc+ss*ss)
%    ee=CalcKappa(ss, 0)
     
    % calculate estimate from resample
      
    [Z, V, W] = Vector_Stats_Bootstrap_Algor(phi);
    
    CBSB = Z0 - V0*W*(Z - Z0);
    CB = CBSB(1);
    SB = CBSB(2);
    SS = sqrt(CB*CB + SB*SB);
    est = CalcKappa(SS, 0); 
       %correction for bias and small sample - Fisher, 1993, p. 88 (4.41)
    if N < 18
      if est < 2
        est = max(est - 2/(N*est), 0);
      else
        est = est*(N - 1)^3 / (N + N^3);
      end
    end
    BStraps(iii) = est;
    
end

% calculate confidence interval
   
SBStraps = sort(BStraps);
    
ind1 = fix(0.5 + B*alfa/2);
ind2 = B - ind1;
    
K1 = SBStraps(ind1+1);
K2 = SBStraps(ind2);

clear BStraps SBStraps phi
  