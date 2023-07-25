function [start_end_s, PARAM, features] = Spindle_detector_conv_nerual_net(LFP,sFreq,sleep_intervals,PARAM)
% function [start_end_s, PARAM, features] = Spindle_detector_conv_nerual_net(LFP,sFreq,sleep_intervals,PARAM)
% The big idea is to start with seeds based on traditional features of spindsle - expert knowledge.
% such as their duration, frequency space, what noise looks like, what REM
% looks like, what waking looks like. With these initial inputs, make some
% good first-pass guesses as to spindles using a simple threshold approach.
%  Feed this, along with a higher dimensional input into the CNN with
%  labeleld REM, spindle, non-spindle, waking data so that the net learns
%  to distinguish. Reject bad choices - like short-duration spindles and
%  perhaps retrain a few times until the system settles.
%
% What about echo-state nets -- looking at the Wikipedia stuff, indicates
% that echo state is a nice way to model systems, but CNNs will perform
% better on higher-dimensional data. They both solve the same essential
% problem.
%

%INPUT
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

SIGMA = 3;
ff_spin = filtfilt(F.Sigma_filt,double(LFP(:,2)));
en = abs(hilbert(ff_spin));
LFP(:,SIGMA) = en;
THETA = 4;
ff = filtfilt(F.Theta_filt,double(LFP(:,2)));
en = abs(hilbert(ff));
LFP(:,THETA) = en;
MU = 5;
ff = filtfilt(F.Mu_filt,double(LFP(:,2)));
en = abs(hilbert(ff));
LFP(:,MU) = en;
%
Sindex = LFP(:,SIGMA)./sqrt(LFP(:,THETA).*LFP(:,MU));
SdiffMu = LFP(:,SIGMA) - LFP(:,MU)*1.2;
SdiffTh = LFP(:,SIGMA) - LFP(:,THETA)*.8; % correct a little for 1/f.

% like a sig to noise. Somewhat independent of power.
SdiffMuP = (LFP(:,SIGMA) - LFP(:,MU))/(LFP(:,SIGMA) + LFP(:,MU));

% 

GIX = SdiffMu > 0 & SdiffTh > 0; % sigma has to be > theta or mu as criterion 1.
C = Count_contiguous(GIX);
GIX = GIX(C > round(sFreq/2));

Sindex2 = Sindex;
Sindex2(~GIX) = nan;


if nargout == 0
    figure
    plot(LFP(:,2))
    hold on
    plot(ff_spin)
    plot(LFP(:,SIGMA))
    plot(LFP(:,THETA))
    plot(LFP(:,MU))
    plot(double(GIX)*10)
    legend('raw','filt','sig','th','mu','gix')
    yyaxis right
    plot(Sindex)
    hold on
    plot(Sindex2)
    % the question now is - is the index better than just using the raw sigma
    % power after the difference filter?
    
    
    figure
    plot(LFP(GIX,2))
    hold on
    plot(ff_spin(GIX))
    
    plot(LFP(GIX,SIGMA))
    plot(LFP(GIX,THETA))
    plot(LFP(GIX,MU))
    legend('raw','filt','sig','th','mu','gix')
end