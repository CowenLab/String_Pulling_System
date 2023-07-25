function [Yvect, NcntL, NcntH] = Vector_1way_SetupBoot_TestKappa(q, ...
                                                     UseFrq, Azims, CatN)

%Vector_1way_SetupBoot_TestKappa.m

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Sets up the data for doing bootstrap tests on Kappa.
% Essentially puts the data into single array, across the categories, 
% for individual or grouped data.

% Input variables:
%   q: number of samples to be analyzed
%   UseFrq: 0 = data input as individual azimuths
%           1 = data input as azimuth column, plus q columns of counts
%   Azims: Array of azimuths to be processed, in radians
%   CatN: sample sizes for each subsample, plut total sample size
% Output variables:
%   Yvect: vector containing combined data
%   NcntL; index in array of start of each subsample data
%   NcntH: index in array of end of each subsample data


NTot = CatN(q+1);
[Nr, Nc] = size(Azims);

% put all data into a single array

Yvect = zeros(NTot, 1);
NcntL = zeros(q, 1);   NcntH = zeros(q, 1);
ijk = 0;

for iii = 1:q
    
    if UseFrq == 0
        NcntL(iii) = ijk + 1;
        N = CatN(iii);
        for jjj = 1:N
            ijk = ijk + 1;
            Az = Azims(jjj, iii);
            Yvect(ijk) = Az;
        end
        NcntH(iii) = ijk;
    else
        NcntL(iii) = ijk + 1;
        for jjj = 1:Nr
            N = Azims(jjj, iii);   Az = Azims(jjj, q+1);
            for iijj = 1:N
                ijk = ijk + 1;
                Yvect(ijk) = Az;
            end
        end
        NcntH(iii) = ijk;    
    end
    
end


