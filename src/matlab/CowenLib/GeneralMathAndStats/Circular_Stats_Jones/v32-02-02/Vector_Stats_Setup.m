function Azims = Vector_Stats_Setup(AzData, NColAz, NColFrq, DegRad)

%Vector_Stats_Setup.m

% Copyright C 2004  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Set up the input data for calculations:
%  1. Convert from degrees to radians, according to DegRad
%  2. If data consists of Class-Midpoint Azimuths and Class 
%     Frequencies (NColFrq > 0), convert to separate, repeated
%     Azimuths in array Azims
%  3. If NColFrq = 0, copy input Azimuth data into array Azims

% Input variables:
%   AzData: Array containing azimuths (or class midpoints) (degrees)
%           and optionally class frequencies
%   NColAz: Column in array AzData that contains Azimuths
%   NColFrq: Column in array AzData that contains Class Frequencies
%           if NColFRQ > 0
%   DegRad: Input azimuths in degrees (0) or radians (1)
% Output variables:
%   Azims: Vector of Azimuths (radians) that are ready for calculation

% set up the data
   
if NColFrq > 0 
    % set up for frequency count data (NColFrq > 0)
    Freqs = AzData(:, NColFrq);
    AzVals = AzData(:, NColAz);
    mmm = sum(Freqs);
    Azims = zeros(1,mmm);
    mmm = 1; 
    for iii = 1:length(AzVals)
        nnn = Freqs(iii);
        if nnn > 0
            aaa = AzVals(iii);
            if DegRad == 0
                aaa = aaa/57.3;
            end
            Azims(mmm:mmm+nnn-1) = aaa;
            mmm = mmm + nnn;
        end    
    end
    clear Freqs, AzVals
else
    % set up for non-frequency data
    if DegRad == 0
       Azims = AzData(:, NColAz)/57.3;
    else
       Azims = AzData(:, NColAz);
    end
end


