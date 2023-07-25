function [bad_start_end, good_start_end, BADIX, LFP_mv] = SPEC_artifact_detection(...
    LFP_mv, ...
    sFreq, ...
    threshold_mv, ...
    flatline_thresh_mv, ...
    time_s_before_after_artifact_to_blank, ...
    PLOT_IT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Detect artifacts - return start and end indices.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% INPUT: LFP in mv (must be in mV)
%        sampling rate
%        threshold for rejection for artifact (mV - of absolute value of LFP signal). Do this by hand.
%        threshold BELOW WHICH data will be rejected when a moving average
%          (e.g., for example when data becomes 0 because the headstage
%          is removed.)
%        flatline thresh - for example if the headstage gets unplugged.
%        time_s_before_after_artifact_to_blank the time to blank out around an artifact.
%        to plot or not to plot.
%
% OUTPUT:
%
% start and end intervals of bad indices and good indices in the LFP.
% BADIX = indices of the bad events.
% LFP_mV optional re-baseline-subtracted LFP.
% 
% TODO: Add a high-frequency filter for detecting artifact. Say - 200 Hz
% and above. Look for peaks in this. Lindsey is working on this.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 4 || isempty(flatline_thresh_mv)
    flatline_thresh_mv = 0.005; % Get suspicious if the background noise is lower than this.
end
if nargin < 5 || isempty(time_s_before_after_artifact_to_blank)
    % the time to blank out around an artifact.
    time_s_before_after_artifact_to_blank = 1.5; % 2.0
end

if nargin < 6
    PLOT_IT = false;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
USE_LOCAL_MAX_OF_DIFF = true; % Seems to work well.
USE_NEO_AND_HIGH_PASS_FILTER = true; % Seems to work well.
USE_SPECTROGRAM_SHAPE = false; % experimental - do not use
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
local_max_of_diff_ratio_threshold = 45; %ratio of the local: max(abs(diff(LFP)))/median(abs(diff(LFP)). This finds fast jumps in the LFP. Head bonks typically. Hard coded for now and probably does not catch much beyond the threshold.
local_max_window_sec = 1;
merge_adjacent_bad_interval_sec = 2; % merge adjacent bad-intervals that are <= to this amount of time apart.
BADIX = false(size(LFP_mv));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% the following should not be necessary if the data has been filtered
% properly but we'll do it just the same.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mn = trimmean(LFP_mv(1:100:end),10);
LFP_mv = LFP_mv - mn;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get rid of flat lines (probably disconnected - when RMS is tooooo low)...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(flatline_thresh_mv)
    BADIX(movmean(abs(diff([0;LFP_mv])),2*round(sFreq)) < flatline_thresh_mv) = true;
    BADIX(movmean(abs(LFP_mv), 2*round(sFreq)) < flatline_thresh_mv) = true;
end
BADIX(isnan(LFP_mv)) = true;
BADIX(isinf(LFP_mv)) = true;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fix baseline.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mn = trimmean(LFP_mv(~BADIX),10);
LFP_mv = LFP_mv - mn;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Threshold detection.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BADIX(abs(LFP_mv) > threshold_mv) = true;
% Add some time around bad times to get rid of nearby bad intervals.
BADIX = convn(BADIX,ones(round(sFreq*time_s_before_after_artifact_to_blank)),'same'); %
BADIX = BADIX >0;

mn = trimmean(LFP_mv(~BADIX),10);

% LFP_mv = LFP_mv - mn;
LFP_mv = LFP_mv - mean(LFP_mv(~BADIX));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Local max. This gets a few clear artifacts. a thresh of ~40 seems safe
% enough to avoid too many false positive.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if USE_LOCAL_MAX_OF_DIFF
    %%%%%%%%%%%%%%%%%%
    % Look for local peaks. Perhaps this should be high-pass filtered
    % before running?
    %%%%%%%%%%%%%%%%%%
    local_md_base_diff_window_sec = 10;
    d = abs(diff(LFP_mv));
    mx =    movmax(d,sFreq*local_max_window_sec);
    md = movmedian(d,sFreq*local_max_window_sec*local_md_base_diff_window_sec); 
    %
    md(end+1) = md(end);
    %use a wider window for the median.
    %     allmed = median(d(1:100:end));
    mx(end+1) = mx(end);
    %     md(end+1) = md(end);
    %     v2 = mx./md;
    v = mx./md;
    BADIX(v > local_max_of_diff_ratio_threshold) = true;
    if PLOT_IT
        figure(991);
        clf
        subplot(2,1,1)
        plot(mx)
        hold on
        %         plot(md)
        yyaxis right
        plot(LFP_mv)
        
        subplot(2,1,2)
        plot(v)
        yyaxis right
        hold on
        plot(LFP_mv)
    end
end

if USE_SPECTROGRAM_SHAPE
    %%%%%%%%%%%%%%%%%%
    % Use spectrogram shape...
    % This is in development. Do not use in practice as it requires assumptions
    % that could cause false negatives. (throwing out the baby)
    %%%%%%%%%%%%%%%%%%
    window = 2^nextpow2(round(sFreq)); % move in 1 s chunks = but make it a power of 2 to speed things up.
    overlap = 0;
    nfft = 256;
    [~,f,bin_ctr_ix,SPEC] = spectrogram(LFP_mv,window,overlap,nfft,sFreq);
    f_ix(1) = find(f > 3,1,'first');f_ix(2) = find(f > 70,1,'first');
    v = SPEC(f_ix(2),:)-(SPEC(f_ix(1),:));
    v = (sum(10*log10(SPEC))).^2;
    if PLOT_IT
        figure(992)
        clf
        subplot(3,1,1);imagesc(bin_ctr_ix/3600,f,10*log10(SPEC));ylabel('Hz');xlabel('h');colormap(jet);axis xy
        %         subplot(3,1,2);imagesc(bin_ctr_ix/3600,f,SPEC);ylabel('Hz');xlabel('h');colormap(jet);axis xy
        subplot(3,1,3);
        %     plot(bin_ctr_ix/3600,SPEC(fix(1),:));ylabel('ratio');xlabel('h');axis tight
        hold on
        %     plot(bin_ctr_ix/3600,SPEC(fix(2),:));ylabel('ratio');xlabel('h');axis tight
        plot(bin_ctr_ix/3600,v);ylabel('ratio');xlabel('h');axis tight
        x_h = linspace(0,length(LFP_mv)/(sFreq*3600),length(LFP_mv));
        yyaxis right
        plot(x_h(1:10:end),LFP_mv(1:10:end))
    end
end
if USE_NEO_AND_HIGH_PASS_FILTER
    %%%%%%%%%%%%%%%%%%
    % FROM http://ieeexplore.ieee.org/xpls/icp.jsp?arnumber=6513197&tag=1#fig_9
    % This is in development. Do not use in practice as it requires assumptions
    % that could cause false negatives. (throwing out the baby)
    %%%%%%%%%%%%%%%%%%
    % Step 1: High pass to 200 Hz and above.
    LFP_mv_hp = 0 % filtered LFP goes here.
    % Step 2: Do a local neo
    NEO = [0 LFP_mv_hp.^2] - [LFP_mv_hp(1:end) 0] .* [ LFP_mv_hp(3:end) 0 0];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute the bad intervals.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[bad_start_end, good_start_end] = find_intervals(double(BADIX(:)),.5,[],[],round(sFreq)*merge_adjacent_bad_interval_sec); % merge adjacents that are < 2s

bad_start_end  = round(bad_start_end);
good_start_end = round(good_start_end);

if PLOT_IT
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure(993)
    clf
    plot(LFP_mv);
    hold on
    plot(BADIX * threshold_mv)
    plot(    bad_start_end(:,1),zeros(size(bad_start_end(:,1)))+threshold_mv,'g>')
    plot(    bad_start_end(:,2),zeros(size(bad_start_end(:,1)))+threshold_mv,'r*')
    axis tight
    box off
    ylabel('mV')
    xlabel('samples')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end