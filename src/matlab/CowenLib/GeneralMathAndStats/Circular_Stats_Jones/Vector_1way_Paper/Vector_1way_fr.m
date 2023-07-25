function fr = Vector_1way_fr(q, Yvect, NcntL, NcntH, CatReTheta);

% Vector_1way_fr.m

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Calculates the fr statistic used in the tangential method of testing
% for equality of Kappas.

% Input variables:
%   q: number of samples to be analyzed
%   Yvect: vector containing combined data
%   NcntL; index in Yvect array of start of each subsample data
%   NcntH: index in array of end of each subsample data
%   CatReTheta: vector means for each subsample, plus total sample size,
%        with resampled data
% Output variables:
%   fr: test statistic for this version of the resample
 

NTot = NcntH(q);     Yvect2 = zeros(NTot, 1);
Dsum = zeros(q, 1);  DBar = zeros(q, 1);   DBarbar = 0;

% get sums

for iii = 1:q
    
    N1 = NcntL(iii);   N2 = NcntH(iii);
    Thet = CatReTheta(iii)/57.3;
    Yvect2(N1:N2) = abs(sin(Yvect(N1:N2) - Thet));
    Dsum(iii) = sum(Yvect2(N1:N2));
    DBarbar = DBarbar + Dsum(iii);
    DBar(iii) = Dsum(iii)/(N2 - N1 + 1);
    
end

DBarbar = DBarbar/NTot;

% calculate statistics

df1 = q - 1;   df2 = NTot - q;
UUU = 0;  VVV = 0;
for iii = 1:q
    N2 = NcntH(iii);  N1 = NcntL(iii);  DB = DBar(iii);
    UUU = UUU + (N2 - N1 + 1)*(DB - DBarbar)^2;
    for jjj = N1:N2
       VVV = VVV + (Yvect2(jjj) - DB)^2;
    end
end

fr = df2*UUU/(df1*VVV);

clear Yvect2
    
    