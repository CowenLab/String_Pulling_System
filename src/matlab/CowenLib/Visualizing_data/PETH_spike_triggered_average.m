function [STA_norm_trials,STA_x_mS, STA_trials] = ...
    PETH_spike_triggered_average(EEG_t_mS_data, alignments_t_mS, before_ms, after_ms, sFreq, shuf_jitter_mS, PLOT_IT)
% Compute a spike triggered average and do controls for the many
% statistical violations of STAs (e.g., independent samples and impact of
% non-stationarieties)
%
% INPUT: 1) time x continuous matrkx, 2) timestamps for alignment, 3,4)
% window before and after STA, 5) sampling rate, 6) amount of jitter for
% shuffle control. Should be at least as big as before_ms + after_ms, 7) to
% plot or not.
%
% Cowen 2020
%%
if nargin < 7
    PLOT_IT = false;
end
if nargout == 0
    PLOT_IT = true;
end
if nargin < 6
    shuf_jitter_mS = before_ms + after_ms; % jitter the size of the window.
end
nShuff = 100;
samples_before = round((before_ms/1000)*sFreq);
samples_after = round((after_ms/1000)*sFreq);

[STA_trials, ~, tmp] = PETH_EEG_simple(EEG_t_mS_data, alignments_t_mS, samples_before, samples_after, sFreq, false);
STA_x_mS = tmp*1000;
mn_SH = zeros(size(STA_trials));
% sh_STA_trials = nan(nShuff,Cols(STA_trials));
% parfor iShuf = 1:nShuff
for iShuf = 1:nShuff
    t = alignments_t_mS + rand(size(alignments_t_mS))*shuf_jitter_mS-shuf_jitter_mS/2; % shift randomly by 6 seconds.
    [tmp] = PETH_EEG_simple(EEG_t_mS_data,t, samples_before, samples_after, sFreq);
    %     STA_trials_v = STA_trials_v - tmp;
    mn_SH = mn_SH + tmp;
    %     sh_STA_trials(iShuf,:) = nanmean(tmp);
end
mn_SH = mn_SH/nShuff;
% This gets rid of issues related to non-stationarities. It partly
% addresses issue of independence. Not entirely though.
STA_norm_trials = STA_trials - mn_SH;

if PLOT_IT
    %M = standardize_range(M')';
    figure
    subplot_ij(2,2,1,1)
    imagesc(STA_x_mS,[],sort_matrix(STA_norm_trials,'min'))
    colormap(jet)
    % Change the color scale.
    caxis_min = prctile(STA_trials(~isnan(STA_norm_trials)),1);
    caxis_max = prctile(STA_trials(~isnan(STA_norm_trials)),99);
    caxis([caxis_min caxis_max]);
    title('Norm STA')
    colorbar_label
    
    subplot_ij(2,2,1,2)
    imagesc(STA_x_mS,[],sort_matrix(STA_trials,'min'))
    colormap(jet)
    % Change the color scale.
    caxis_min = prctile(STA_trials(~isnan(STA_trials)),1);
    caxis_max = prctile(STA_trials(~isnan(STA_trials)),99);
    caxis([caxis_min caxis_max]);
    colorbar_label
    
    title('Raw STA')
    
    subplot_ij(2,2,2,1)
    plot_confidence_intervals(STA_x_mS,STA_norm_trials)
    % plot(x,nanmean(M))
    axis tight
    box off
    plot_vert_line_at_zero
    plot_horiz_line_at_zero
    
    subplot_ij(2,2,2,2)
    
    plot_confidence_intervals(STA_x_mS,STA_trials)
    % plot(x,nanmean(M))
    axis tight
    box off
    plot_vert_line_at_zero
end