function [bins, PETHdata, height] = PETHFR2( eventTS, spikeTS, varargin )
%
% usage : [bins, PETHdata] = PETH( eventTS, spikeTS, varargin )
%
% function to create and plot a PETH for the given event timestamps and
% spike timestamps
%
% INPUTS:
%       eventTS - timestamps of events around which to make the PETHs
%       spikeTS - spike timestamps
%
% OUTPUTS:
%       bins - vector containing bin centers
%       PETHdata - vector of counts for each bin
%
% variable arguments:
%   binsize - the size of the bins; default 20 ms
%   timerange - 1 x 2 vector with the amount of time before and after each
%       event (default 1 second each direction)
%   plotpeth - whether or not to make a plot; 0 = no, 1 = yes (default 1)

timeRange = [-5 5]; %default should be [-1 1]
binSize = 0.04;
plotPETH = 1;

for iarg = 1 : 2 : nargin - 2

    switch lower(varargin{iarg})
        
        case 'binsize',
            binSize = varargin{iarg + 1};
            
        case 'timerange',
            timeRange = varargin{iarg + 1};
            
        case 'plotpeth',
            plotPETH = varargin{iarg + 1};
            
    end    % end switch
    
end    % end for iarg...

bins = [timeRange(1) + (binSize / 2) : binSize : timeRange(2) - (binSize / 2)];

PETHdata = zeros(1, length(bins));
for iEvent = 1 : length(eventTS)
    
    timeBounds = eventTS(iEvent) + timeRange;
    relSpikes = spikeTS(and(spikeTS > timeBounds(1), spikeTS < timeBounds(2)))...
        - eventTS(iEvent);
    
    temp = hist(relSpikes, bins);
    
    if size(temp, 1) > size(temp, 2)
        % if the histogram is all zeros, for some reason the hist function
        % is returning a column vector instead of a row vector
        temp = temp';
    end    % end if size...
    
    PETHdata = PETHdata + temp;
   
end    % end for iEvent...
 PETHdata = PETHdata/binSize;
 PETHdata = PETHdata/length(eventTS);

if plotPETH
    
     figure
height = max(PETHdata) + max(PETHdata)/4;
heightrange = [0.0 height];

    bar(bins, PETHdata, 'k');
    set(gca, 'xlim', timeRange)
     ax = axis;line([0 0], [ax(3) ax(4)],'Color','k')

end