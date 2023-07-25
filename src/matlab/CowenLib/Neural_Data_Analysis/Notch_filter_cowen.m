function [d] = Notch_filter_cowen( fs, f_notch_low, f_notch_high)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [d] = Notch_filter_cowen( fs, f_notch_low,f_notch_high)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% run by...
% 
% >> new_sig = filtfilt(d,sig);
%
% Works MUCH better than notch_filter() 
%  fs = 1000;
% cowen 2017
% cowen 2018 - moved this up to an 8th order filter to reduce sideband
% effect. Expanded the default range a bit to deal with the new precision.
% 
% TODO: This does not get rid of the harmonic. See Chronux tool rmlinesc
% for that. An iir comb filter might be best for this but that requires a new
% toolbox.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Here is an attempt at the chronux approach...
%
% addpath( genpath(fullfile(Home_dir,'Toolboxes','chronux_2_12')))
% 
% params.Fs = downsample_fq; % sampling frequency, same for LFP and spike
% params.fpass = [0 downsample_fq/2]; % frequency range  of interest
% params.tapers = [10 19]; % emphasize smoothing for the spikes
% params.pad = 0; %
% % tapers, Fs, fpass, pad
% d = rmlinesc(LFP(:,2),params,[],1,60);
% rmpath( genpath(fullfile(Home_dir,'Toolboxes','chronux_2_12')))
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 2
    f_notch_low = 59.85;
end
if nargin < 3
    f_notch_high = 60.15;
end

d = designfilt('bandstopiir','FilterOrder',10, ...
    'HalfPowerFrequency1',f_notch_low,'HalfPowerFrequency2',f_notch_high, ...
    'DesignMethod','butter','SampleRate',fs);

% freqz(d,[],fs)
% [b,a] = iircomb(fs/60,35,'notch'); % requires special toolbox.
% freqz(b,a,fs)

if nargout == 0
    
    fvtool(d,'Fs',fs)
    
end