function [CC,Cell_Combos,xdim,stats,CCshuff] = CrossCorr_from_all_files(tfiles, xcorr_window_msec, xcorr_bin_size_msec, start_end_ts, plot_it, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [CC,Cell_Combos] = CrossCorr_from_all_files(tfiles, xcorr_window_msec, xcorr_bin_size_msec, start_end_ts, plot_it)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perform a cross correlation analysis on all combinations of the files
% specified in tfiles.
%
% INPUT: tfiles - cell array of tfiles - OR - the user could pass in a cell
%     array of timestamps or ts objects. (.1msec)
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
%         Cell_combos = cell combinations
%         xdim - x dimension for plotting.
%         stats = structure of stat information for the xcorr
%
% example:
%   [CC,d] = CrossCorr_from_all_files(ff,500,3,[10562374745/100 13562374745/100],1)
%
% TODO: Add a > 1 adjacent bin below threshold for monosynaptic connection-
% given artifact from recording blackout. This may also be good for above
% threshold to get rid of some noise.
%
% Hippocampal pyramidal cell-interneuron spike transmission is frequency
% dependent and responsible for place modulation of interneuron discharge %
% Marshall L, Henze DA, Hirase H, Leinekugel X, Dragoi G, Buzsaki G.
%  Used a shuffle correction - subtracted the shuffle and THEN determined
%  significance.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 6
    options = [];
end
[istrue] = strcmp('shuffle_correction',options);
if sum(istrue)>0
    SHUFFLE_CORRECTION = true;
else
    SHUFFLE_CORRECTION = false;
end
nShuff = 6;
% Did the user pass in tetrode ID's?
[istrue] = strcmp('tetrode_id',options);
if sum(istrue)>0
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % User passed in the tetrode ID for each cell - allowing use to ignor
    % the middle bin for within tetrode comparisons as Cheetah blanks out
    % during this period.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ix = find(istrue);
    tetrode_ids = options{ix+1};
    if length(tetrode_ids) ~= length(tfiles)
        error('Tetrode IDs are not of the same length as the tfile list')
    end
    TETRODE_CORRECTION = true;
else
    TETRODE_CORRECTION = false;
    tetrode_ids = [];
end
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

if isstr(tfiles{1})
    % User passed in a file name.
    S = Load_tfiles(tfiles);
else
    % User passed in a cell array of timestamps.
    if isa(tfiles{1},'ts')
        disp('TS OBJECTS IDENTIFIED')
        for ii = 1:length(tfiles)
            S{ii} = Data(tfiles{ii})*100; % Convert to usec
        end
    else
        S = tfiles;
    end
end
[Cell_1_idx, Cell_2_idx]  = find(triu(ones(length(S))));
stats.monosynaptic_stats = zeros(length(Cell_1_idx),4)*nan;
stats.monosynaptic_is_above = zeros(length(Cell_1_idx),1)*nan;
stats.monosynaptic_is_below = zeros(length(Cell_1_idx),1)*nan;
stats.monosynaptic_stats_desc = {'monosynaptic_threshold_upper' 'monosynaptic_threshold_lower' 'minimum' 'maximum'};
stats.global_stats   = zeros(length(Cell_1_idx),4)*nan;
stats.global_ttest   = zeros(length(Cell_1_idx),1)*nan;
stats.is_significant = zeros(length(Cell_1_idx),3); % Whether or not this was a significant xcorr or not.
stats.global_stats_desc = {'global_threshold_upper' 'global_threshold_lower' 'minimum' 'maximum'};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Restrict to the proper times
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SSshuff = cell(nShuff,length(S));
for iC = 1:length(S)
    if isempty (start_end_ts)
        % shuffle all spike ISI's
        Sshuff{iC}  = ISI_shuffle(S{iC});
        Sshuff2{iC} = ISI_shuffle(S{iC});
    else
        % compute the shuffle independently for each interval.
        if 1
            for iShuff = 1:nShuff
                [Sshuff{iShuff,iC}, S{iC}] = ISI_shuffle(S{iC},start_end_ts);
            end
        else
            SS = [];
            for iInterval = 1:rows(start_end_ts)
                goodix = find(S{iC} >= start_end_ts(iInterval,1) & S{iC} <= start_end_ts(iInterval,2));
                SS = [SS; S{iC}(goodix)];
                for iShuff = 1:nShuff
                    SSshuff{iShuff,iC}  = [SSshuff{iShuff,iC} ; ISI_shuffle(S{iC}(goodix))];
                end
            end
            S{iC} = sort(SS);
            for iShuff = 1:nShuff
                Sshuff{iShuff,iC}  = sort(SSshuff{iShuff,iC});
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CC = zeros(length(Cell_1_idx),nbins );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii = 1:length(Cell_1_idx)
    if isempty(S{Cell_1_idx(ii)}) | isempty(S{Cell_2_idx(ii)})
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Do nothing since one cell does not fire.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    else
        t = S{Cell_2_idx(ii)};
        a = S{Cell_1_idx(ii)};
        % Following is used to do a little shifting of the timestamps to
        % minimize binning edge problems.
        [CCx, xdim] = CrossCorrCount(a, t, xcorr_bin_size_msec, nbins);
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
            [CC1, xdim] = CrossCorrCount(a + o1*xcorr_bin_size_msec*.2*10, t , xcorr_bin_size_msec , nbins);
            [CC3, xdim] = CrossCorrCount(a + o2*xcorr_bin_size_msec*.2*10, t , xcorr_bin_size_msec , nbins);
            CC(ii,:) = nanmean([CC1';CCx';CC3']); %This wierdness gets rid of some binning edge issues.
        else
            CC(ii,:) = CCx;
        end
        CCshuff_tmp = zeros(size(CCx));
        for iShuff = 1:nShuff
            CCshuff_tmp  = CCshuff_tmp + CrossCorrCount(a, Sshuff{iShuff,Cell_2_idx(ii)}, xcorr_bin_size_msec, nbins);
        end
        CCshuff(ii,:) = CCshuff_tmp/nShuff; % Mean

        if SHUFFLE_CORRECTION
            CC(ii,:) = CC(ii,:) - CCshuff(ii,:);
        end
        if TETRODE_CORRECTION
            if tetrode_ids(Cell_1_idx(ii))==tetrode_ids(Cell_2_idx(ii))
                % Make the mid bin the mean of the surrounding bins.
                % I could also Nan this - perhaps that is best
                CC(ii,mid) = nan;
                %                CC(ii,mid) = mean(CC(ii,[mid-1 mid+1]));
            end
        end
        % Verify with PETH_raster: RESULTS - the same so the code is
        % working.
        %[M,am,xdim2] = PETH_raster(S{Cell_2_idx(ii)},S{Cell_1_idx(ii)},xcorr_bin_size_msec,xcorr_window_msec/2,xcorr_window_msec/2);
        %if Rows(M) == 1
        %   cr = M;
        %else
        %   cr = mean(M);
        %end

        if Cell_1_idx(ii) == Cell_2_idx(ii)
            % Autocorr
            CC(ii,mid) = nan;
            CCshuff(ii,mid) = nan;
            % CC(ii,mid) = CC(ii,mid+1); % Set 0 value to an adjacent value.
            % CCshuff(ii,mid) = CCshuff(ii,mid+1);
        end
        %%%%%%%%%%%%%%%%%
        % Monosynaptic
        %%%%%%%%%%%%%%%%%
        test      = CC(ii,monosynaptic_test_range_bins);
        control   = CC(ii,monosynaptic_control_range_bins);
        monosynaptic_threshold_upper = nanmean(control) + nanstd(control)*thresh_sd_monosynaptic; %
        monosynaptic_threshold_lower = nanmean(control) - nanstd(control)*thresh_sd_monosynaptic; %
        stats.monosynaptic_stats(ii,:) = [monosynaptic_threshold_upper monosynaptic_threshold_lower nanmax(test) nanmin(test)];
        stats.monosynaptic_stats(ii,:) = [monosynaptic_threshold_upper monosynaptic_threshold_lower nanmax(test) nanmin(test)];
        stats.monosynaptic_is_above(ii) = nanmax(test) > monosynaptic_threshold_upper ;
        stats.monosynaptic_is_below(ii) = nanmin(test) < monosynaptic_threshold_lower ;
        %%%%%%%%%%%%%%%%%
        % Global - use the shuffle statistic, assume poisson process, take
        %%%%%%%%%%%%%%%%%
        % Tried percentile - not as good. Tends to be too low.
        %  [up_low] = prctile(CCshuff(ii,:),[99.9 .01]);
        global_threshold_upper = nanmean(CCshuff(ii,:)) + nanstd(CCshuff(ii,:))*thresh_sd; %
        global_threshold_lower = nanmean(CCshuff(ii,:)) - nanstd(CCshuff(ii,:))*thresh_sd; %

        stats.global_stats(ii,:) = [global_threshold_upper global_threshold_lower nanmax(CC(ii,:)) nanmin(CC(ii,:))];
        if sum(CC(ii,:)) > 0
            [h,p]=ttest2(CC(ii,:),CCshuff(ii,:),0.01);
        else
            p = 1;
        end
        stats.global_ttest(ii) = [p];
    end
end

if isempty(xdim)
    xdim = linspace(-xcorr_window_msec/2,xcorr_window_msec/2,size(CC,2));
end
%figure;subplot(1,2,1); imagesc(CC);subplot(1,2,2);imagesc(CCshuff)

stats.is_significant(:,1) = stats.monosynaptic_stats(:,3) > stats.monosynaptic_stats(:,1) + stats.monosynaptic_stats(:,4) < stats.monosynaptic_stats(:,2);
stats.is_significant(:,2) = stats.global_stats(:,3) > stats.global_stats(:,1) + stats.global_stats(:,4) < stats.global_stats(:,2);
stats.is_significant(:,3) = stats.global_ttest > 0.005;

Cell_Combos = [Cell_1_idx(:) Cell_2_idx(:)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%f2 = figure;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if plot_it
    % Convert tfiles to strings for plotting purposes
    if ~isstr(tfiles{1})
        tmptfiles = cell(length(tfiles),1);
        for ii = 1:length(tfiles)
            tmptfiles{ii} = num2str( ii );
        end
        tfiles_str = tmptfiles;
    end

    for ii = 1:length(Cell_1_idx)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if sum(CC(ii,:)) >0
            tstr = '';
            if stats.monosynaptic_is_above(ii) > 0
                tstr = 'MONO_ABOVE';
            end
            if stats.monosynaptic_is_below(ii) > 0
                tstr = [tstr 'MONO_BELOW'];
            end
            clf
            plot_crosscorr(CC(ii,:),xdim,20);

            a    = axis;
            plot([a(1) a(2)], [stats.monosynaptic_stats(ii,1) stats.monosynaptic_stats(ii,1)],'r:')
            plot([a(1) a(2)], [stats.monosynaptic_stats(ii,2) stats.monosynaptic_stats(ii,2)],'g:')
            text(a(1), stats.monosynaptic_stats(ii,1), 'Mono')
            text(a(1), stats.monosynaptic_stats(ii,2), 'Mono')
            plot([a(1) a(2)], [stats.global_stats(ii,1) stats.global_stats(ii,1)],'r-.')
            plot([a(1) a(2)], [stats.global_stats(ii,2) stats.global_stats(ii,2)],'g-.')
            %
            xlabel('msec'); ylabel('Count')
            [p,f1,e] = fileparts(tfiles_str{Cell_1_idx(ii)});
            [p,f2,e] = fileparts(tfiles_str{Cell_2_idx(ii)});
            title(['XCorr ' f1 ' Vs ' f2 ' [' num2str(Cell_1_idx(ii)) ' ' num2str(Cell_2_idx(ii)) '] Thresh ' num2str(stats.monosynaptic_stats(ii,1)) ' ' num2str(stats.monosynaptic_stats(ii,2)) ' p=' num2str(stats.global_ttest(ii)) '_' tstr],'Interpreter','none');
            box off
            saveas(gcf,[f1 '_Vs_' f2 '_Combo_' num2str(Cell_1_idx(ii)) '_' num2str(Cell_2_idx(ii)) '_' tstr '.png'])
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
    end
end