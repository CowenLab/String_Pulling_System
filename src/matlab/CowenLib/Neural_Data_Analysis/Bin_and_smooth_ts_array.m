function [NT,edges, binctrs] = Bin_and_smooth_ts_array(CA, small_binsize, smooth_win_size, shuffle_bins)
% Simple function for binning and smoothing spikes.
% Simplification of bin_ts_array.
%
% Cowen 2020
if nargin < 3
    smooth_win_size = [];
end
if nargin < 4
    shuffle_bins = false;
end
knl_fun = @hanning; % Smoothing function.

st = min(cell2mat(CA(:)));
ed = max(cell2mat(CA(:)));

edges = st:small_binsize:ed;
NT = nan(length(edges)-1, length(CA));
for iS = 1:length(CA)
    NT(:,iS) = histcounts(CA{iS},edges);
    if shuffle_bins
        % Good for control
        ix = randperm(length(NT(:,iS)));
        NT(:,iS) = NT(ix,iS);
    end
    if ~isempty(smooth_win_size)
        %         NT(:,iS) = conv_filter(NT(:,iS),hamming(smooth_win_size));
        NT(:,iS) = conv_filter(NT(:,iS),knl_fun(smooth_win_size));
    end
end
if nargout > 2
    binctrs = edges(1:end-1) + small_binsize/2;
end