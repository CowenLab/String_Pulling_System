function [FF,SD,OC,xb] = Frequency_fields_1D_by_trial(POS,LFPpos,n_place_bins,RANGES,bands)
%function [MN,SD,OC,xb] = Frequency_fields_1D(POS,LFPpos,n_place_bins,bands)
%
% Place field but for frequency bands - or any continuous data (e.g. EMG)
%
% INPUT: POSITION: time, x
%        LFP: Each col is a filtered lfp signal (each col is a frequency
%          band). This must be ALIGNED with the POS data so it's the same
%          number of rows as the position data.
%        n_place_bins = resolution of the position plotting OR pass in a vector
%        of bin edges.
%        band_labels (optional) - for plotting.
%
% OUTPUT: MN mean value of LFPpos at each location
%         SD std of LFPpos at each location
%         OC occupancy (amount of times each spot was visited) - convert to
%            seconds by dividing by tracker sampling frequency.
%         position_edges = the x positions for the 1D positions
% Cowen.

if Rows(POS) ~= Rows(LFPpos)
    error('POS and LFP must have the same number of rows.')
end

if nargin < 5
    bands = [];
end

FF = zeros(Rows(RANGES), n_place_bins, Cols(LFPpos));
SD = zeros(Rows(RANGES), n_place_bins, Cols(LFPpos));
OC = zeros(Rows(RANGES), n_place_bins);

if length(n_place_bins) == 1
   bin_edges = linspace(min(POS(:,2)),max(POS(:,2)) + 0.000001, n_place_bins+1);
   % NEED TO ADD 1 
    % We need to add just a tiny amount to the end as the histc for bi
    % edges will doa less than (<) for the higher edge. (EDGES(k) <= X(i)
    % < EDGES(k+1))
else
    bin_edges = n_place_bins;
end

for iT = 1:Rows(RANGES)
    POS_tmp = Restrict(POS,RANGES(iT,:)); % This could be dangerous - it will limit the range.
    LFPpos_tmp = Restrict([POS(:,1) LFPpos],RANGES(iT,:));
    [tFF,tSD,tOC,xb] = Frequency_fields_1D(POS_tmp,LFPpos_tmp(:,2:end),bin_edges);
    FF(iT,:,:) = tFF;
    SD(iT,:,:) = tSD;
    OC(iT,:) = tOC;
    % fprintf('.')
end

if ~isempty(bands)
    % Plot the data.
    for iBand = 1:Cols(LFPpos)
        subplot(Cols(LFPpos)/2,2,iBand)
        [mn ci] = normci(squeeze(FF(:,:,iBand)));
        plot_confidence_intervals(1:length(mn),mn,ci)
        if iscell(bands)
            title(bands{iBand})
        else
            title(num2str(bands(iBand,:)))
        end
    end
    equalize_axes
end
