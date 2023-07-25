function CDFval = Vector_Stats_CDF(Azims, Thet, Kap)

%Vector_Stats_CDF.m

% Copyright C 2004  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Integrate vonMises distribution from 0 to input angle (Val), and 
% return the CDF value (that is, prob(angle<=Val).  Does this for
% every angle in the input data set (Azims)

% Variables input:
%   Azims: Vector of angles (radians) in dataset to integrate to 
%   Thet: Vector mean of vonMises distribution
%   Kap: Concentration parameter of vonMises distribution
% Variable output:
%   CDFval: Vector of calculated CDFs

Nincs = 5000;
const = 2*pi*Besseli(0,Kap);
CDFval = zeros(length(Azims),1);

% loop over the data points

for iii = 1:length(Azims)
    
    Val = Azims(iii);
    Val1 = -Thet; Val2 = Val - Thet; 
    
    % integrate to this datapoint's angle
    xx=linspace(Val1, Val2, Nincs);     
    yy=exp(Kap*cos(xx));      
    F=sum(yy)*Val/Nincs/const;
    
    % save in vector for output
    CDFval(iii) = F;
    
end

clear Nincs const Val xx yy F
