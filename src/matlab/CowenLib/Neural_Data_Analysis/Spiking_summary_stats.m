function [SS,BRST] = Spiking_summary_stats(t_msec, varargin)
% function [SS,BRST] = Spiking_summary_stats(t_msec, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Useful for computing a variety of spiking stats and autocorrs and things.
% 
% Computes standard summary stats for spiking...
% Calculates bursting.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
binsize_log10_ms = 0.1;
trim_thresh_sec = 5; % consider ISI greater than this an aberration - at least for calculting things like LV or CV or Fano - outliers can bias these measures.
burst_detect_method = 'LogISIPasquale'; % Cotterill, E., Charlesworth, P., Thomas, C. W., Paulsen, O., & Eglen, S. J. (2016). A comparison of computational methods for detecting bursts in neuronal spike trains and their application to human stem cell-derived neuronal networks. Journal of Neurophysiology, 116(2), 306–321. https://doi.org/10.1152/jn.00093.2016
%     burst_detect_method = 'GraceAndBunny'; % 
UPLIM_MS = 1500;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Extract_varargin;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BRST.BurstThreshMsec = [];

SS.MeanRateHz = nan;
SS.MedianRateHz = nan;
SS.MeanRateTrimHz = nan;
SS.LocalVariance = nan;
SS.LocalVarianceRevised = nan;
SS.LocalVarianceTrimmed = nan;
SS.LocalVarianceRevisedTrimmed = nan;
SS.CV = nan;
SS.CVTrimmed = nan;
SS.FanoFactor = nan;
SS.FanoFactorTrimmed = nan;
SS.FanoFactor = nan;
SS.HistISI = nan;
SS.HistISIks = nan;
SS.HistISI_logms_x  = nan;

if length(t_msec) < 5
    return
end

dur_s = (t_msec(end) - t_msec(1))/1000;
dt = diff(t_msec);
dt_trim = dt(dt < trim_thresh_sec*1000);
%%
SS.MeanRateHz = length(t_msec)/dur_s;
SS.MeanRateTrimHz =  1000/mean(dt_trim);
SS.MedianRateHz = 1000/median(dt);
[SS.LocalVariance, SS.LocalVarianceRevised] = LocalVariance(dt);
[SS.LocalVarianceTrimmed, SS.LocalVarianceRevisedTrimmed] = LocalVariance(dt,trim_thresh_sec*1000);
SS.CV = std(dt)/mean(dt);
SS.CVTrimmed = std(dt_trim)/mean(dt_trim);
% SS.CVTrimmed = trimstd(dt,[5 95])/trimmean_cowen(dt,[5 95]);
SS.FanoFactor = var(dt)/mean(dt);
SS.FanoFactorTrimmed = var(dt_trim)/mean(dt_trim);
%
dt = dt(dt>0);
[SS.HistISI, x] = histcounts(log10(dt),0:binsize_log10_ms:log10(UPLIM_MS)); % Parameters from Pasquale
SS.HistISI_logms_x = x(1:end-1) + diff(x)/2;
[SS.AutoCorr, SS.Autocorr_x_ms] = AutoCorr(t_msec,2,200);
[M, x] = ksdensity(log10(dt));
SS.HistISIks = interp1(x,M,SS.HistISI_logms_x);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout > 1
    %% This will be its own function someday.
    BRST = Burst_analysis(t_msec, burst_detect_method);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout == 0
    figure
    subplot(1,2,1)
    plot(10.^SS.HistISI_logms_x,SS.HistISI);
    set(gca,'XScale','log')
    yyaxis right
    plot(10.^SS.HistISI_logms_x,SS.HistISIks);
    xlabel('log ISI ms')
    subplot(1,2,2)
    plot(SS.Autocorr_x_ms, SS.AutoCorr)
    axis tight
    xlabel('ms')
end