function RandVals = VonMises_GenerateRandomRad(N, ThetR, Kap)

%VonMises_GenerateRandomRad.m

% Copyright C 2006  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Generate N random variates from VonMises distribution with
% vector mean Thet and concentration Kap - input and out in radians
% Ref.: Fisher, 1993, p. 49

% Input variables-
%   N = number of values desired
%   ThetR = mean direction, radians
%   Kap = concentration
% Output variable -
%   RandVals = vector of randomly generated azimuths, radians

RandVals = zeros(N,1);

a = 1 + sqrt(1 + 4*Kap^2);
b = (a - sqrt(2*a))/(2*Kap);
r = (1 + b^2)/(2*b);

for iii = 1:N
    
    done = 0;
    while done == 0
        U1 = unifrnd(0,1);
        z = cos(pi*U1);
        f = (1 + r*z)/(r + z);
        c = Kap*(r - f);
        
        U2 = unifrnd(0,1);
        if c*(2 - c) - U2 > 0 | log(c/U2) + 1 - c >= 0
            U3 = unifrnd(0,1);
            RandVals(iii) = ThetR + sign(U3 - 0.5)*acos(f);
            if RandVals(iii) < 0 
                RandVals(iii) = RandVals(iii) + 2*pi;
            end
            if RandVals(iii) > 2*pi 
                RandVals(iii) = RandVals(iii) - 2*pi;
            end
            done = 1;
        end
    end
    
end
        

