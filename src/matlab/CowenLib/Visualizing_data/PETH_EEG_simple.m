function [M, ix, x_sec] = PETH_EEG_simple(EEG_t_data, alignments_t, samples_before, samples_after,sFreq, PLOT_IT)
%% A far simpler version than my PETH_EEG program - which is very hard to
%% debug but does a lot of extra things.
%
% INPUT: EEG_t_data = 2 col matrix - first col is time, second is the data.
%        alignments_t = the timestamps of the times to be aligned.
%        samples_before = samples before to capture on each event.
%        samples_after  = samples after to capture on each event.
%        sFreq (optional) - for plotting only.
%
% events outside the range are turned into Nans.
%
% cowen 2012

if nargin < 5
    sFreq = 1;
end
if nargin < 6
    PLOT_IT = false;
end
if nargout == 0
    PLOT_IT = true;
end

if isa(EEG_t_data,'double') || isa(EEG_t_data,'single')
else
    EEG_t_data = double(EEG_t_data);
end

M = [];
ix = [];
x_sec = [];

if isempty(alignments_t)
    return
end

if iscell(alignments_t)
    for ii = 1:length(alignments_t)
        [M{ii}, ix{ii}, x_sec] = PETH_EEG_simple(EEG_t_data, alignments_t, samples_before, samples_after,sFreq, PLOT_IT);
    end
    return
end

samples_before = round(samples_before);
samples_after = round(samples_after);

if 0
    % used these data to validate.
    samples_before = 4;
    samples_after = 6;
    
    EEG_t_data = [1:1000; rand(1,1000)]';
    EEG_t_data(1:20:1000,2) = 1;
    alignments_t = 1:20:1000;
end

eeg_samples = round(interp1(EEG_t_data(:,1)',1:Rows(EEG_t_data),alignments_t));

ix = (-1*samples_before):1:samples_after;
Mix = repmat(ix,length(eeg_samples),1);
for ii =1:length(eeg_samples)
    Mix(ii,:) = Mix(ii,:) + eeg_samples(ii);
end
BADIX = Mix>Rows(EEG_t_data) | Mix<1| isnan(Mix);
Mix(BADIX) = 1;
%
M = EEG_t_data(reshape(Mix,Rows(Mix)*Cols(Mix),1),2);
M = reshape(M, Rows(Mix), Cols(Mix));
M(BADIX) = nan; % records outside of the range.
x_sec = ix/sFreq;

if PLOT_IT
    %M = standardize_range(M')';
    %figure
    subplot(3,1,1:2)
    imagesc(x_sec,[],M)
    %     colormap(jet)
    % Change the color scale.
    caxis_min = prctile(M(~isnan(M)),1);
    caxis_max = prctile(M(~isnan(M)),99);
    caxis([caxis_min caxis_max]);
    pubify_figure_axis
    set(gca,'XTickLabel','')
    plot_vert_line_at_zero

    subplot(3,1,3)
    plot_confidence_intervals(x_sec,M)
    % plot(x,nanmean(M))
    axis tight
    box off
    pubify_figure_axis
    plot_vert_line_at_zero
    subplot(3,1,1:2)
end