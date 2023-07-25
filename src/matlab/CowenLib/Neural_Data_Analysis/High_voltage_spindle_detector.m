function [start_end_s, PAR, non_hvs_times,HVS_IX,NOHVS_IX] = High_voltage_spindle_detector(LFP,sFreq,varargin)
% function [start_end_s, PAR, non_hvs_times] = High_voltage_spindle_detector(LFP,sFreq,varargin)
% HVS have strong harmonics. I will use this to hopefully create a better
% detector. NOTE: this could false detect theta as theta can
% have strong harmonics as well so don't use it in the hippocampus.
%
% LFP = npoints x 2 col matrix. 1st col is time in seconds. 2nd col is the EEG
% data. Presumed to be in uV.
% sFreq = the sampling frequency of the data.
%
% Cowen 2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PAR.min_dur_s = .7;
PAR.merge_thresh_s = 2.0;
PAR.peak_fq_centers_hz = [8 16 24 ];
PAR.control_fq_centers_hz = [4 10 20 ];
PAR.buffer_hz = 1.5; % range around each band
PAR.smooth_index_s = 1;
PAR.filt_order = 10;
PAR.thresh_method = 'z'; % vs. val based on difference in voltage.
PAR.thresh = 250;
PAR.thresh_z = 2.5;
PAR.auto_tweak_freq_bands = false;
% sleep_intervals = [0 Rows(LFP)/sFreq]; % you can define targeted regions for analysis.
Extract_varargin;
PAR.thresh_low = PAR.thresh*.6;
PAR.thresh_z_low = PAR.thresh_z*.6;

LFP = double(LFP);
BIX = isnan(LFP(:,2)) | isinf(LFP(:,2));
GIX = ~BIX;
if PAR.auto_tweak_freq_bands
    % Refine and optimize frequencies for spindle detection.
    f = designfilt('bandpassiir','FilterOrder',PAR.filt_order, ...
        'HalfPowerFrequency1',7,'HalfPowerFrequency2',22, ...
        'SampleRate',sFreq);
    env = convn(abs(hilbert(filtfilt(f,LFP(GIX,2)))),hanning(sFreq),'same');
    GIX2 = env > prctile(env,90);
    [p,f] = pwelch(LFP(GIX2,2),sFreq*4,sFreq*2,13.5:.2:20,sFreq);
    % figure;plot(f,p)
    [~,maxix] = max(p);
    maxfq = f(maxix);
    shift = maxfq-PAR.peak_fq_centers_hz(2);
    if abs(shift) >= 2.5 || maxix <=2
        disp('shift is too big, not doing it')
        figure;plot(f,p);title('shift is too big, not doing it')
    else
        PAR.peak_fq_centers_hz = PAR.peak_fq_centers_hz + shift;
        PAR.control_fq_centers_hz = PAR.control_fq_centers_hz + shift;
    end
    % p = 10*log10(p);
end
peak_bands = [PAR.peak_fq_centers_hz(:) - PAR.buffer_hz PAR.peak_fq_centers_hz(:) + PAR.buffer_hz];
control_bands = [PAR.control_fq_centers_hz(:) - PAR.buffer_hz PAR.control_fq_centers_hz(:) + PAR.buffer_hz];
LFP(:,3:5) = zeros(length(LFP(:,2)),3);
for ii = 1:Rows(peak_bands)
    F{ii} = designfilt('bandpassiir','FilterOrder',PAR.filt_order, ...
        'HalfPowerFrequency1',peak_bands(ii,1),'HalfPowerFrequency2',peak_bands(ii,2), ...
        'SampleRate',sFreq);
    env = zeros(Rows(LFP),1);
    env(GIX) = abs(hilbert(filtfilt(F{ii},LFP(GIX,2))));
    LFP(GIX,3) = LFP(GIX,3) + (env(GIX)-median(env(GIX)))/Rows(peak_bands);
end
for ii = 1:Rows(control_bands)
    C{ii} = designfilt('bandpassiir','FilterOrder',PAR.filt_order, ...
        'HalfPowerFrequency1',control_bands(ii,1),'HalfPowerFrequency2',control_bands(ii,2), ...
        'SampleRate',sFreq,'DesignMethod','butter');
    env = zeros(Rows(LFP),1);
    env(GIX) = abs(hilbert(filtfilt(C{ii},LFP(GIX,2))));
    LFP(GIX,4) = LFP(GIX,4) + (env(GIX)-median(env(GIX)))/Rows(peak_bands);
end
LFP(:,5) = LFP(:,3)-LFP(:,4); % simple and seems to work best - fewer false positives.
LFP(:,6) = (LFP(:,5) - trimmean(LFP(:,5),4))/trimstd(LFP(:,5),4); % simple and seems to work best - fewer false positives.
LFP(BIX,2:end) = nan;
% could be improved by then going through each detected HVS with a smoothed
% version to catch the true start time.
% Sindex_env = envelope_cowen(LFP(:,5));
switch PAR.thresh_method
    case 'original_units'
        [start_end_s,non_hvs_times,HVS_IX,NOHVS_IX] = find_intervals([LFP(:,1) LFP(:,5)],PAR.thresh,PAR.thresh_low,PAR.min_dur_s,PAR.merge_thresh_s );
    case 'z'
        [start_end_s,non_hvs_times,HVS_IX,NOHVS_IX] = find_intervals([LFP(:,1) LFP(:,6)],PAR.thresh_z,PAR.thresh_z_low,PAR.min_dur_s,PAR.merge_thresh_s );
end
if nargout == 0
    sk = 3;
    figure
    cols = 2:Cols(LFP);
    for ii = 1:length(cols)
        subplot(length(cols),1,ii)
        plot(LFP(1:sk:end,1)/60,LFP(1:sk:end,cols(ii)))
        axis tight
        hold on
        if ii == 1
            plot_markers_simple(start_end_s/60)
        end
    end
    %     legend('raw','filt','sig','ctr')
    %     plot_markers_simple(start_end_s)
    % the question now is - is the index better than just using the raw sigma
    % power after the difference filter?
end