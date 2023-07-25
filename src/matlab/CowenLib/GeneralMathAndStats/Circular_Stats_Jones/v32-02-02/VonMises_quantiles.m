function q = VonMises_quantiles(NTot, Kap)

%VonMises_quantiles.m

% Copyright C 2004  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Compute quantiles around the vector mean for a vonMises distribution.
% Essentially same as distribution with zero mean.

% Number of quantiles equals the number of data points, NTot, and 
% are equally spaced in probability
% Operates by calculating cumulative vonMises over (0, 360) and saving
% the many small steps in integral.  Then move through the 
% calculated values until reach each desired P and hence get quantile
% that corresponds.  Save in q.  Then shift to range (-180, 180) by 
% subtracting mean used in calculations (q - 180).
% Variables in:
%   NTot: Number of quantiles to calculate
%   Kap: Concentration parameter to use
% Variable output:
%   q: Vector of quantiles corresponding to evenly spaced probs. P

Thet = pi;
Nincs = 5000;
P = transpose(1:NTot)/(NTot + 1);
q = P;
pipi = 2*pi;

% compute cumulative vonMises probabilities

Val = pipi;
const = pipi*Besseli(0,Kap);
xx=linspace(0, Val, Nincs)      ;
yy=exp(Kap*cos(xx-Thet))/const  ;
xxyy(1)=0;
for iii = 2:Nincs
    yy(iii) = yy(iii-1) + yy(iii);
    xxyy(iii) = (yy(iii)/iii)*xx(iii);
end

% calculate inverse values (quantiles) for specified probabilities

for jjj = 1:NTot
    istrt = 2;
    PP = P(jjj);
    for iii = istrt:Nincs
        if xxyy(iii) >= PP
            q(jjj) = (iii-1)*Val/Nincs;
            istrt = iii + 1;
            break
        end
    end
end

q = q - pi;

clear xx xxyy yy P PP istrt const Nincs
