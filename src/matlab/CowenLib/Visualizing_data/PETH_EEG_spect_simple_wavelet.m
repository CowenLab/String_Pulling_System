function [FF, AVG, h] = PETH_EEG_spect_simple_wavelet(EEG_t_sec_data, alignments_t, sFreq, fq_range, x_axis_sec, PLOT_IT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Align wavelet decomposition on events. 
% INPUT: 2 col matrix: col 1 time(sec) col2 data sampled at sFreq
%           alignment times (sec)
%           sFreq 
%           fq_range = the frequency ranges to plot.
%           x_axis_sec of the PETH from a negative number (before event) to a
%           positive number (after event ) in seconds (e.g. -1:.01:1)
%           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 6
    PLOT_IT = true;
end
h = [];
buffer_sec = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% To speed things up, let's cut out data that goes beyond the ranges
% specified. No use wavelet decomping data we don't use.
% important as wavelets are SLOW.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
good_intervals(:,1) = alignments_t + x_axis_sec(1) - buffer_sec;
good_intervals(:,2) = alignments_t + x_axis_sec(end) + buffer_sec;
GIX = false(Rows(EEG_t_sec_data),1);
for ii =1:Rows(good_intervals)
    ix = binsearch_vector(EEG_t_sec_data(:,1), good_intervals(ii,:));
    GIX(ix(1):ix(2)) = true;
end
EEG_t_sec_data = EEG_t_sec_data(GIX,:);

if ~isa(EEG_t_sec_data,'double') || ~isa(EEG_t_sec_data,'single')
    EEG_t_sec_data = double(EEG_t_sec_data);
end

BIX = isnan(EEG_t_sec_data(:,2));
EEG_t_sec_data(BIX,2) = 0;

% if length(fq_range) > 30
% F = [];
%     for iF = 1:length(fq_range)
%        [~, F(iF,:)] = SPEC_waveletdecomp(fq_range(iF),EEG_t_sec_data(:,2),sFreq,5);
%     end
% else
% [~,F] = SPEC_waveletdecomp(fq_range,EEG_t_sec_data(:,2),sFreq,5);
[pow,fqs]=SPEC_cwt_cowen(EEG_t_sec_data(:,2),sFreq,fq_range,32, 0);
F = real(abs(pow));
% end
FF = Align_and_interpolate_on_events(F',EEG_t_sec_data(:,1),alignments_t,x_axis_sec);
%  AVG = nanmean(FF,3)';
AVG = trimmean(FF,10,3)';

if PLOT_IT
    cla
    h(1) = subplot(4,1,1:3);
    imagesc(x_axis_sec,fq_range,log10(AVG));
    colorbar_label('log10 power')
    colormap(jet)
    
    xlabel('sec');ylabel('Hz')
    axis xy
    M = Align_and_interpolate_on_events(EEG_t_sec_data(:,2),EEG_t_sec_data(:,1),alignments_t,x_axis_sec);
    M = squeeze(M)';
    h(2) = subplot(4,1,4);
    plot_confidence_intervals(x_axis_sec,M,[],[0 0 0]);
    subplot(h(1))
end

