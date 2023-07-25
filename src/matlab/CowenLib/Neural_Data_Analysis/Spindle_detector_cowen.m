function [start_end_s, PARAM, features] = Spindle_detector_cowen(LFP,sFreq,sleep_intervals,PARAM)
% INPUT
%
% npoints x 2 col matrix. 1st col is time in seconds. 2nd col is the EEG
% data. Presumed to be in uV.
% sFreq = the sampling frequency of the data.
% sleep_intervals = the start and end times of each contiguous block of
% sleep Seconds.
% params: parameters for detection - a structure. Will change between
% subjects.
%
% PARAM.sigma_range = [10 15]
%
% Cowen 2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3 || isempty(sleep_intervals)
    sleep_intervals = [0 length(LFP)/sFreq];
end
start_end_s = [];
sleep_intervals = Interval_merge(sleep_intervals);
non_sleep_intervals(:,1) = [LFP(1,1)-eps; sleep_intervals(:,2)];
non_sleep_intervals(:,2) = [sleep_intervals(:,1);LFP(end,2) + eps];
% Reduce LFP to just regions of interest to save time and space but add a
% little buffer for edge issues with filtering...
LFP = Restrict(LFP,[sleep_intervals(:,1)-.2 sleep_intervals(:,1)+.2]);
if nargin < 4
    PARAM.min_dur_s = 0.5;
    PARAM.merge_thresh_s = 0.2;
    PARAM.Sigma_range = [10 15];
    PARAM.Theta_range = [5 9];
    PARAM.Mu_range= [16 22]; % Louis does no use this.
    % PARAM.Delta_range = [1 5]; % 1.5-6 in Louis. 0.5 5 in Kreuzer. I chose 1 as there can be some very slow DC changes that do not think are true brain delta.
    % PARAM.Beta_range=[23 32]; % 22-30 in Louis
end

% Create filters....
% If the user already has the filterd traces, then ignore this section.
F.Sigma_filt = designfilt('bandpassiir','FilterOrder',10, ...
    'HalfPowerFrequency1',PARAM.Sigma_range(1),'HalfPowerFrequency2',PARAM.Sigma_range(2), ...
    'SampleRate',sFreq,'DesignMethod','butter');
F.Theta_filt = designfilt('bandpassiir','FilterOrder',10, ...
    'HalfPowerFrequency1',PARAM.Theta_range(1),'HalfPowerFrequency2',PARAM.Theta_range(2), ...
    'SampleRate',sFreq,'DesignMethod','butter');
% F.Delta_filt = designfilt('bandpassiir','FilterOrder',10, ...
%     'HalfPowerFrequency1',PARAM.Delta_range(1),'HalfPowerFrequency2',PARAM.Delta_range(2), ...
%     'SampleRate',sFreq,'DesignMethod','butter');
F.Mu_filt = designfilt('bandpassiir','FilterOrder',10, ...
    'HalfPowerFrequency1',PARAM.Mu_range(1),'HalfPowerFrequency2',PARAM.Mu_range(2), ...
    'SampleRate',sFreq,'DesignMethod','butter');

% Filter the data into core bands.
ff_spin = filtfilt(F.Sigma_filt,double(LFP(:,2)));
en = abs(hilbert(ff_spin));
T.Sigma = en;
ff = filtfilt(F.Theta_filt,double(LFP(:,2)));
en = abs(hilbert(ff));
T.Theta = en;
ff = filtfilt(F.Mu_filt,double(LFP(:,2)));
en = abs(hilbert(ff));
T.Mu = en;

%
T.Sindex = T.Sigma./sqrt(T.Theta.*T.Mu);

T.SdiffMu = T.Sigma - T.Mu*1.2;
T.SdiffTh = T.Sigma - T.Theta*.8; % correct a little for 1/f.
% like a sig to noise. Somewhat independent of power.
T.SdiffMuP = (T.Sigma - T.Mu)./(T.Sigma + T.Mu);

% Make an initial pass at states. Divide up into short sigma events (not
% long enough to be spindles), and also divvy up the non-sigma events into groups) only choose the clearest representatives from each group for the network training. 

GIX = T.SdiffMu > 0 & T.SdiffTh > 0; % sigma has to be > theta or mu as criterion 1.
C = Count_contiguous(GIX);
GIX2 = C > round(sFreq/2); % must last a certain amount of time to be counted.

% Sindex2 = Sindex;
% Sindex2(~GIX) = nan;

% Do linear discriminant 
% O.MdlLinear = fitcdiscr([O.psd O.MVT],O.STATE); %%%% Can handle > 2 classes.
% O.LD_STATE = predict(O.MdlLinear,[O.psd O.MVT]);
% T = table([length(en),1]);


if nargout == 0
    x = LFP(:,1)/3600;
    figure
    plot(x,LFP(:,2))
    hold on
    plot(x,ff_spin)
    plot(x,T.Sigma)
    plot(x,T.Theta)
    plot(x,T.Mu)
    yyaxis right
    plot(x,T.SdiffTh)
    hold on
    plot(x,T.SdiffMuP)
    legend('raw','filt','sig','th','mu','SdiffTh','SdiffMuP')
    % the question now is - is the index better than just using the raw sigma
    % power after the difference filter?
    

end