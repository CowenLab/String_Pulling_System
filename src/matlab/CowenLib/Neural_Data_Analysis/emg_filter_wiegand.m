function [amp_filt_sig, filt_sig] = emg_filter_wiegand(x, sr);

%x is vector
%sr is sampling rate
%smooth_window is in s

lowlimit_fq  = 70;
highlimit_fq = 249;

d = designfilt('bandpassiir','FilterOrder',4, ...
    'HalfPowerFrequency1',lowlimit_fq,'HalfPowerFrequency2',highlimit_fq, ...
    'SampleRate',sr);

filt_sig = filtfilt(d,double(x)); %filtered to spindle band
amp_filt_sig = envelope(sqrt(filt_sig.^2)); %instantaneous amplitude; % He does a hilbert transform here for instantaneous amplitude