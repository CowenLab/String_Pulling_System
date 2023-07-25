function Yvect = VectCnt2IndivAz(Azims, col, DegRad)

% VectCnt2IndivAz.m

% Copyright C 2006  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Takes count-based data and converts it to a long list of 
% individual azimuths.  Last column in Azims array input holds
% azimuths, and preceding q (= NC-1) columns holds frequencies.

% Input variables:
%    Azims: array of azimuths (radians) (size NRxNC)
%    col: which column to convert (if col > 0)
%         if col = 0, convert all data into a single vector
%    DegRad: output form to save:  0 = save as degrees; 
%                                  1 = save as radians
% Output variable:
%    Yvect: vector that contains the individual azimuths, either
%         in degrees or radians, and from one column or all

% set up

[NR, NC] = size(Azims);
if col == 0
    NNN = sum(sum(Azims(:, 1:NC-1)));
else
    NNN = sum(Azims(:, col));
end
Ycnt = zeros(NR, 1);
Yvect = zeros(NNN, 1);

% collect all counts for total sample into single list by azimuth

if col == 0
    for iii = 1:NR
        Ycnt(iii) = sum(Azims(iii, 1:NC-1));
    end
else   
    Ycnt = Azims(:, col);      
end

% process for one column, whether precombined total or individ. column

ijk = 0;
for iii = 1:NR
    Az = Azims(iii, NC);
    if DegRad == 0; Az = Az*57.3; end;
    N = Ycnt(iii);
    if N > 0
        for jjj = 1:N;
            ijk = ijk + 1;
            Yvect(ijk) = Az;
        end
    end
end

clear Ycnt

