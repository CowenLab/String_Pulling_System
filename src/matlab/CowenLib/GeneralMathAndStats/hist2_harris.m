% out = hist2(Data, nXBins, nYBins)
%
% Makess a 2d histogram of the data.
% nXBins and nYBins are optional arguments
% which give the number of grid segments.
% - default is 50.
%
% modified by Cowen 2010

function out = hist2_harris(Data, nXBins, nYBins, min_max_X, min_max_Y)

% Ignore Nans (cowen)
Data = Data(~isnan(sum(Data,2)),:);


if (nargin<2) nXBins = 50; end
if (nargin<3) nYBins = 50; end

if nargin < 4
    % Default
    MinX = min(Data(:,1));
    MaxX = max(Data(:,1));
    MinY = min(Data(:,2));
    MaxY = max(Data(:,2));
else
    MinX = min_max_X(1);
    MaxX = min_max_X(2);
    MinY = min_max_Y(1);
    MaxY = min_max_Y(2);
end

out = zeros(nXBins, nYBins);

% The following 4 lines confuse me.
XBin = floor(1 + nXBins*(Data(:,1) - MinX) / (MaxX - MinX));
% Percent divergence from the left of the range times the number of bins
YBin = floor(1 + nYBins*(Data(:,2) - MinY) / (MaxY - MinY));

XBin(XBin == nXBins+1) = nXBins;
YBin(YBin == nYBins+1) = nYBins;

for i = 1:size(Data,1)
	out(XBin(i), YBin(i)) = out(XBin(i), YBin(i)) + 1;
end

%imagesc(out)

% Written by Kenneth D. Harris 
% This software is released under the GNU GPL
% www.gnu.org/copyleft/gpl.html
% any comments, or if you make any extensions
% let me know at harris@axon.rutgers.edu