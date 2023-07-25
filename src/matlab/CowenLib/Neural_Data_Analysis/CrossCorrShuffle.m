function [CC,CCsh,xdim,stats] = CrossCorrShuffle(t1, t2, xcorr_window_msec, xcorr_bin_size_msec, start_end_ts, plot_it)
%function [CC,CCsh,xdim,stats] = CrossCorrShuffle(t1, t2, xcorr_window_msec, xcorr_bin_size_msec, start_end_ts, plot_it)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perform a cross correlation analysis on a combination of timestamps.
%  Performa a suffle correction as well.
%
% INPUT: t1, t2 - timestamps to compare = vector of times.
% MICROSECONDS!!!!!
%        xcorr_windows_msec  = window for xcorr (MUST BE AT LEAST A SECOND)
%        xcorr_bin_size_msec = bin size. Use a binsize of 1msec if you want
%          accurate monosynaptic coupling information
%          (see stats.monosynaptic_stats)
%        start_end_ts = restrict times - same units as the timestamps.
%        plot_it = set to 1 if you want to plot it and save as a png in the
%          current directory.
%        options = additional options in a cell array
%              'shuffle_correction' - return crosscorrs AFTER a shuffled
%              version of the target cell has been subtracted.
%
% OUTPUT: CC = cross correlagrams
%         CCsh - shuffle.
%         xdim - x dimension for plotting.
%         stats = structure of stat information for the xcorr
%
% example:
%
% Hippocampal pyramidal cell-interneuron spike transmission is frequency
% dependent and responsible for place modulation of interneuron discharge %
% Marshall L, Henze DA, Hirase H, Leinekugel X, Dragoi G, Buzsaki G.
%  Used a shuffle correction - subtracted the shuffle and THEN determined
%  significance.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CC = [];CCsh = [];xdim = [];stats = [];
if nargin < 6
    plot_it = 1;
end
%
if isequal(t1,t2)
    is_acorr = 1;
else
    is_acorr = 0;
end

nShuff = 26;
%
JITTER_TIMESTAMPS = false;% Add some small jitter to the reference spikes to minimize binning noise.
% Don't do this for monosynaptic comparisons as
% within-tetrode bins around 0 will inheret some
% of the blankout around the 0 bin.

thresh_sd = 3; % number of standard deviations above the mean for
% something to be considered above threshold. - this is not
% for monosynaptic thresholds.
thresh_sd_monosynaptic = 3.5; % number of standard deviations above the mean for
% something to be considered above threshold. (Marshal et
% al. 2002) used 3sd
nbins     = round(xcorr_window_msec / xcorr_bin_size_msec);
xdim = [];
% We need an odd number of bins
if mod(nbins,2) == 0
    nbins = nbins + 1;
end
mid = floor(nbins/2) + 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Range for testing for significant monosynaptic connections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
monosynaptic_test_range_bins = (mid-ceil(3/xcorr_bin_size_msec)):(mid+ceil(3/xcorr_bin_size_msec));
monosynaptic_control_range_bins = [(mid-ceil(50/xcorr_bin_size_msec)):(mid-ceil(10/xcorr_bin_size_msec)) (mid+ceil(10/xcorr_bin_size_msec)):(mid+ceil(50/xcorr_bin_size_msec))];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Range for testing for significant xcorr in general
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if 0
    global_control_range_bins = [(mid-495/xcorr_bin_size_msec):(mid-445/xcorr_bin_size_msec)] ;
    global_control_range_bins = unique(round(global_control_range_bins));
    global_test_range_bins = [(mid-435/xcorr_bin_size_msec): (mid+435/xcorr_bin_size_msec)] ;
    global_test_range_bins = unique(round(global_test_range_bins));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    divisor_to_seconds = 1e4;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Restrict to the proper times and create shuffle timestamps.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%SSshuff = cell(nShuff,2);

% This is somewhat redundant with ISI_shuffle with intervals, but it is
% much faster.
if isempty (start_end_ts)
    % shuffle all spike ISI's
    for iShuff = 1:nShuff
        Sshuff1{iShuff} = Shuffle_ISIs(t1);
        Sshuff2{iShuff} = Shuffle_ISIs(t2);
    end

else
    % compute the shuffle independently for each interval.
    t1 = Restrict(t1, start_end_ts(:,1), start_end_ts(:,2));
    t2 = Restrict(t2, start_end_ts(:,1), start_end_ts(:,2));
    for iShuff = 1:nShuff
        Sshuff1{iShuff} = [];
        Sshuff2{iShuff} = [];
    end

    for iInterval = 1:Rows(start_end_ts)
        goodix1 = t1 >= start_end_ts(iInterval,1) & t1 <= start_end_ts(iInterval,2);
        goodix2 = t2 >= start_end_ts(iInterval,1) & t2 <= start_end_ts(iInterval,2);
        % restrict existing timestmaps to be within the specified range.
        if sum(goodix1)>0
            for iShuff = 1:nShuff
                Sshuff1{iShuff} = [Sshuff1{iShuff}; Shuffle_ISIs(t1(goodix1))];
                Sshuff2{iShuff} = [Sshuff2{iShuff}; Shuffle_ISIs(t2(goodix2))];
            end
        end
    end
    for iShuff = 1:nShuff
        Sshuff1{iShuff}  = sort(Sshuff1{iShuff});
        Sshuff2{iShuff}  = sort(Sshuff2{iShuff});
    end
end
CC = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(t1) || isempty(t2)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Do nothing since one cell does not fire.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

else
    % Following is used to do a little shifting of the timestamps to
    % minimize binning edge problems.
    [CC, xdim] = CrossCorrCount(t1, t2, xcorr_bin_size_msec, nbins);
    CCsh = nan(size(CC));
    if JITTER_TIMESTAMPS
        % Add some jitter to the xcorr to help with binning boundary issues.
        % This worries me for monosynaptic studies as the 0 bin
        % blankout period on within tet cells will spill over a little
        % to the adjacent bins. As a result, I am not using it for
        % monosynaptic but it may be quite useful for other xcorr plots.
        o1 = ones(size(a));
        o2 = o1;
        o1(1:2:end) = -1;
        o2(2:2:end) = -1;
        [CC1] = CrossCorrCount(t1 + o1*xcorr_bin_size_msec*.2*10, t2 , xcorr_bin_size_msec , nbins);
        [CC3, xdim] = CrossCorrCount(t1 + o2*xcorr_bin_size_msec*.2*10, t2 , xcorr_bin_size_msec , nbins);
        CC(:) = nanmean([CC1';CCx';CC3']); %This wierdness gets rid of some binning edge issues.
    end
    CCsh_tmp = zeros(size(CC));
    for iShuff = 1:nShuff
        CCsh_tmp  = CCsh_tmp + CrossCorrCount(t1, Sshuff2{iShuff}, xcorr_bin_size_msec, nbins);
    end
    CCsh = CCsh_tmp/nShuff; % Mean

    % Verify with PETH_raster: RESULTS - the same so the code is
    % working.
    %[M,am,xdim2] = PETH_raster(S{Cell_2_idx(ii)},S{Cell_1_idx(ii)},xcorr_bin_size_msec,xcorr_window_msec/2,xcorr_window_msec/2);
    %if Rows(M) == 1
    %   cr = M;
    %else
    %   cr = mean(M);
    %end

    if is_acorr
        % Autocorr
        CC(mid) = nan;
        CCsh(mid) = nan;
        % CC(mid) = CC(mid+1); % Set 0 value to an adjacent value.
        % CCsh(ii,mid) = CCsh(ii,mid+1);
    end
    %%%%%%%%%%%%%%%%%
    % Monosynaptic
    %%%%%%%%%%%%%%%%%
    test      = CC(monosynaptic_test_range_bins);
    control   = CC(monosynaptic_control_range_bins);
    monosynaptic_threshold_upper = nanmean(control) + nanstd(control)*thresh_sd_monosynaptic; %
    monosynaptic_threshold_lower = nanmean(control) - nanstd(control)*thresh_sd_monosynaptic; %
    stats.monosynaptic_stats = [monosynaptic_threshold_upper monosynaptic_threshold_lower nanmax(test) nanmin(test)];
    stats.monosynaptic_stats = [monosynaptic_threshold_upper monosynaptic_threshold_lower nanmax(test) nanmin(test)];
    stats.monosynaptic_is_above = nanmax(test) > monosynaptic_threshold_upper ;
    stats.monosynaptic_is_below = nanmin(test) < monosynaptic_threshold_lower ;
    %%%%%%%%%%%%%%%%%
    % Global - use the shuffle statistic, assume poisson process, take
    %%%%%%%%%%%%%%%%%
    % Tried percentile - not as good. Tends to be too low.
    %  [up_low] = prctile(CCsh,[99.9 .01]);
    global_threshold_upper = nanmean(CCsh) + nanstd(CCsh)*thresh_sd; %
    global_threshold_lower = nanmean(CCsh) - nanstd(CCsh)*thresh_sd; %

    stats.global_stats = [global_threshold_upper global_threshold_lower nanmax(CC) nanmin(CC)];
    if sum(CC) > 0
        [~,p]=ttest2(CC(:),CCsh,0.01);
    else
        p = 1;
    end
    stats.global_ttest = p;
end

if isempty(xdim)
    xdim = linspace(-xcorr_window_msec/2,xcorr_window_msec/2,size(CC,2));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%f2 = figure;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if plot_it
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~isempty(CC) && nansum(CC) >0
        tstr = '';
        if stats.monosynaptic_is_above > 0
            tstr = 'MONO_ABOVE';
        end
        if stats.monosynaptic_is_below > 0
            tstr = [tstr 'MONO_BELOW'];
        end
        clf
        plot_crosscorr(CC(:)' - CCsh(:)',xdim,5,[],is_acorr);
        a    = axis;
        if is_acorr == 0
            plot([a(1) a(2)], [stats.monosynaptic_stats(1) stats.monosynaptic_stats(1)],'r:')
            plot([a(1) a(2)], [stats.monosynaptic_stats(2) stats.monosynaptic_stats(2)],'g:')
            text(a(1), stats.monosynaptic_stats(1), 'Mono')
            text(a(1), stats.monosynaptic_stats(2), 'Mono')
            plot([a(1) a(2)], [stats.global_stats(1) stats.global_stats(1)],'r-.')
            plot([a(1) a(2)], [stats.global_stats(2) stats.global_stats(2)],'g-.')
            title(['Thresh ' num2str(stats.monosynaptic_stats(1)) ' ' num2str(stats.monosynaptic_stats(2)) ' p=' num2str(stats.global_ttest) '_' tstr],'Interpreter','none');
        end
        %
        xlabel('msec'); ylabel('Count')
        pubify_figure_axis
        %            saveas(gcf,[f1 '_Vs_' f2 '_Combo_' num2str(Cell_1_idx(ii)) '_' num2str(Cell_2_idx(ii)) '_' tstr '.png'])
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
end