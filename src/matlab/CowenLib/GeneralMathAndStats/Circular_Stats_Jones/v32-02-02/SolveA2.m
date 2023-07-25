function KapHat = SolveA2(IntVal)

%SolveA2.m

% Copyright C 2004  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Look up kappa value from input R-bar value for function
%                  A2(KapHat)=Rbar
%                  where A2 = I2/I0
% See Fisher, 1993, p. 50

% Variable input:
%   IntVal: value to be interpolated
% Variable output:
%   KapHat: kappa

% A2 array contains calculations of A2 function for various kappa values

if IntVal <= 0.996
    
% if here, use table to interpolate
   % compute A2 values for various kappa

    kappa1=(0:1:10);
    kappa2=(12:2:50);
    kappa3=(55:5:100);
    kappa=[kappa1 kappa2 kappa3];
    for iii=1:41
        kap=kappa(iii);
        A2(iii) = besseli(2,kap)/besseli(0,kap);
    end
    A2(42) = 0.9960;
    kappa(42) = 500;

   % set up table and interpolate

    A2table = [transpose(A2) transpose(kappa)];
    
    KapHat = interp1(A2table(:,1), A2table(:,2), IntVal, 'cubic');
    
else
    
% if here, off end of table - set to large value    
    KapHat = 500;
    
end
    
    
    
    
