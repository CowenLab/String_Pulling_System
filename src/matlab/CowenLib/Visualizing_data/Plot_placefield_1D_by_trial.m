function [PF,x_axis,TC,OCC] = Plot_placefield_1D_by_trial(TS,POS,RANGES,n_place_bins,smooth_factor,plot_it)
%function [PF,TC,Occ] = Plot_placefield_1D_by_trial(TS,POS,RANGES,n_place_bins,smooth_factor,plot_it)
% Plots 1 dimensional placefields for different ranges of time but unlike
% it's sister function, this function treats row in RANGES as a trial and
% thus computes the individual place fields for each trial and then
% averages them across trials.
% 
% INPUT:
%   TS - timestamps (a vector) - Assumes its in uSec
%   RANGES - 2 col matrix of start and end times - Assumes uSec.
%   bin granularity OR pass in a vector of bin edges (see histc)
%   degree of smoothing (empty if no smoothing)
%   whether or not to plot the field.
%
% OUTPUT:
%   place field, rate map, and occupancy.
% 
% Cowen(2009)
%
TC = []; OCC = []; x_axis = [];PF = [];

if nargin < 6 || nargout == 0
    plot_it = 1;
end

if nargin < 5
    smooth_factor = []; % NOTE: Numbers above 100 lead to artifactual emphasis of high occupancy locations. Perhaps this is due to some small offset in spike and positoin timing.
end

if nargin < 4
    n_place_bins = 80; 
end

if iscell(TS)
    for iC = 1:length(TS)
        if plot_it
            figure
        end
        [PF{iC},x_axis,TC{iC},Occ] = Plot_placefield_1D_by_trial(TS{iC}, POS, RANGES, n_place_bins, smooth_factor, plot_it);
    end
    return
end

% Restrict spikes
TS = Restrict(TS,RANGES);
%

% x axis
if length(n_place_bins) == 1
    bin_edges = linspace(min(POS(:,2)),max(POS(:,2)) + 0.000001, n_place_bins+1); % adding the small number catches the last edge.
else
    bin_edges = n_place_bins;
    n_place_bins = length(bin_edges)-1;       
end
PF = zeros(Rows(RANGES),n_place_bins);
TC = zeros(Rows(RANGES),n_place_bins);
OCC = zeros(Rows(RANGES),n_place_bins);

for iT = 1:Rows(RANGES)
    [pf tc oc] = Plot_placefield_1D(TS,POS,RANGES(iT,:),bin_edges,smooth_factor,0);
    if any(isnan(pf(:)))
       error('nan')
    end
    if ~isempty(tc)
        PF(iT,:) = pf(:,2)';
        TC(iT,:) = tc(:,2)';
        OCC(iT,:) = oc(:,2)';
    end
end

if nargout > 1
    if isempty(POS)
        x_axis = [];
    else
    [pf] = Plot_placefield_1D(TS,POS,RANGES,bin_edges,smooth_factor,0);
    x_axis  = pf(:,1)';
    end
end

if plot_it
    imagesc(PF)
    [mn ci] = normci(PF);
    plot_confidence_intervals(1:length(mn),mn,ci)
end
