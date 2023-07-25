function [PF,TC,Occ,bin_edges] = Plot_placefield_1D(TS, POS, RANGES, n_place_bins, smooth_factor, plot_it)
% Plots 1 dimensional placefields for different ranges of time
% INPUT:
%   TS - timestamps (a vector) - Assumes its in uSec
%   RANGES - 2 col matrix of start and end times - Assumes uSec.
%   n_place_bins = bin granularity OR pass in a vector of bin edges, BUT,
%    bin_edges has the intervals for each bin so the nBins returned is
%    length(bin_edges)-1. x(t)<=bin<x(t+1) so you may want to add a little
%    to the last bin.
%
%   smooth_factor = degree of smoothing (empty if no smoothing)
%   plot_it = whether or not to plot the field.
%
% OUTPUT:
% place field, rate map, and occupancy.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen(2009)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PF = [];     TC = [];     Occ = []; bin_edges = [];
if nargin < 6 || nargout == 0
    plot_it = 1;
end

if isempty(POS)
    disp('No Position Data - empty.')
    return
end

if nargin < 5
    smooth_factor = []; % NOTE: Numbers above 100 lead to artifactual emphasis of high occupancy locations. Perhaps this is due to some small offset in spike and positoin timing.
end

if nargin < 4
    n_place_bins = 80; % NOTE: Numbers above 100 lead to artifactual emphasis of high occupancy locations. Perhaps this is due to some small offset in spike and positoin timing.
end

if nargin < 3
    RANGES = [];
end

if iscell(TS)
    for iC = 1:length(TS)
        if plot_it
            figure
        end
        [PF{iC},TC{iC},Occ,bin_edges] = Plot_placefield_1D(TS{iC}, POS, RANGES, n_place_bins, smooth_factor, plot_it);
    end
    return
end

if length(n_place_bins) == 1
    % The following is stupid, but it's what you need to do for hist c.
    bin_edges = linspace(min(POS(:,2)),max(POS(:,2)) + 0.000001, n_place_bins+1);
    bin_edges(end+1) = bin_edges(end) + 0.000001; % This bin will be deleted

else
    bin_edges = n_place_bins;
end

if ~isempty(RANGES)
    if RANGES(1) > RANGES(2)
        RANGES
        error('Ranges are not ascending')
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Restrict 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    POSr = Restrict(POS,[RANGES(:,1)-1000 RANGES(:,2)+1000]);
    TS = Restrict(TS,RANGES);
else
    POSr = POS;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Spikes at each position
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SFx = ScatterFields({TS/100}, tsd(POS(:,1)/100, POS(:,2)));
SFx = ScatterFields_cowen(POSr,TS); %  binsearch_vector is really the same as scatterfields

if ~isempty(SFx)
    spikes_at_each_position = histcounts(SFx(:,2), bin_edges);
else
    spikes_at_each_position = zeros(length(bin_edges)-1,1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Time at each position. (mean of interval before this point and interval
% after.)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%tend = POS(end-1,1) - POS(end,1);
%tstart = POS(2,1)-POS(1,1);

%t_at_pos = [tstart; t_at_pos; tend];
%
%SFt = ScatterFields({TS/100}, tsd(POS(:,1)/100, t_at_pos));
%[POSx] = ScatterFields({POS(:,1)/100}, tsd(POS(:,1)/100, POS(:,2)));

occ = histcounts(POSr(:,2), bin_edges)'; % is this true????? - Yes. IS IT REALLY. Shouldn't I be taking the time at each position?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Smooth - but be careful - this can lead to artifact if you are not
% careful.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(smooth_factor)
    S = hanning(smooth_factor)/sum(smooth_factor);
    occ = convn(occ(:),S,'same');
    spikes_at_each_position = convn(spikes_at_each_position,S,'same');
end

bin_ctrs = bin_edges(1:end-1) + (bin_edges(2) - bin_edges(1))/2;
bin_ctrs = bin_ctrs(:);

PF  = zeros(length(bin_ctrs),2);
PF(:,1) = bin_ctrs;
IX = spikes_at_each_position>0;
if ~any(IX)
    % NO SPIKES AT ANY POSITION.
    return
end
if any(occ(IX)==0)
    ix = find(occ(IX)==0);
    for ii = 1:length(ix)
        if ix(ii) > 1 && ix(ii) > length(occ)
            occ(ix(ii)) = (occ(ix(ii)-1) + occ(ix(ii) + 1))/2;
        elseif ix(ii) == 1
            occ(ix(ii)) = occ(ix(ii)+1);
        elseif ix(ii) == length(occ);
            occ(ix(ii)) = occ(ix(ii)-1);
        end
    end
    disp([mfilename ' zero occupancy at a location with a spike. May be due to a rounding error.'])
end
%occ_sec = occ / pos_sFreq; % Amount of time in seconds the animals spent in each location. 
%PF(IX,2) = spikes_at_each_position(IX)./(occ_sec(IX)); %  + eps ???
spikes_at_each_position = spikes_at_each_position(:);
PF(IX,2) = spikes_at_each_position(IX)./(occ(IX)); %  + eps ???
%IX = occ>0; % zero means nothing, plus dividing by 0 is bad.
%PF(IX,2) = spikes_at_each_position(IX)./(occ(IX)); %  + eps ???
%PF(isinf(PF(:,2)),2) = nan; % Convert infs to nans.

if nargout > 1 || plot_it
    TC  = zeros(length(bin_ctrs),2);
    TC(:,1:2)  = [bin_ctrs(:) spikes_at_each_position(:)];
    Occ  = zeros(length(bin_ctrs),2);
    Occ(:,1:2) = [bin_ctrs(:) occ(:)];
end

if plot_it
    subplot(3,1,1)
    plot(TC(:,1),TC(:,2))
    ylabel('TC - spikes')
    subplot(3,1,2)
    plot(Occ(:,1),Occ(:,2))
    ylabel('OCC - seconds')
    subplot(3,1,3)
    plot(PF(:,1),PF(:,2))
    ylabel('PF - template bin')
end