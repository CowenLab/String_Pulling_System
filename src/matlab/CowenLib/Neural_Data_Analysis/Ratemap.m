function [RM,OC,PF,xdim,ydim] = Ratemap(POS,TS,nXBins, nYBins, min_max_X, min_max_Y)
% Compute the ratemap and if the user desires, also compute the occupancy
% and place field.
%
%  POS = 3 column (time x y) matrix
%  TS = vector of timestamps
%       
%   (This replaces the overly complicated TuningCurves function.)
%   Aside from being simpler, it's also about 3 times faster.
%
% Cowen 2010
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Defaults:
if nargin < 3
    nXBins = 50;
end
if nargin < 4
    nYBins = 50;
end

if nargin < 5
    min_max_X = [nanmin(POS(:,2)) nanmax(POS(:,2))];
end

if nargin < 6
    min_max_Y = [nanmin(POS(:,3)) nanmax(POS(:,3))];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Start of critical code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
POS = double(POS);
% Find the indices in the position data that most closely line up with the
% spikes.

POS_IX = binsearch_vector(POS(:,1),TS);

% Compute the ratemap.
RM = hist2_harris(POS(POS_IX,2:3),nXBins,nYBins,min_max_X,min_max_Y);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% End of critical code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Occupancy and place field.
if nargout > 1
    OC = hist2_harris(POS(:,2:3),nXBins,nYBins,min_max_X,min_max_Y);
    PF = RM./(OC+eps); % The placefield - the eps prevents nan's from creeping in.
end

% Axes of the ratemap.
if nargout > 3
    xdim = linspace(min_max_X(1),min_max_X(2),nXBins);
    ydim = linspace(min_max_Y(1),min_max_Y(2),nYBins);
end