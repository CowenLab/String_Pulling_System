function [RIP, RIP_INFO] = Ripple_detector_cowen(D,sFreq, varargin)
%
% INPUT: 
% D = 2 column matrix where the first col is time in microseconds
% Presumes that the data has been pre-filtered to just include 
% intervals_to_analyze = nx2 matrix of start and end times in D that are
% valid for analysdis (e.g., animal is not moving.).
% PRESUMES: data (second column) is in uV.
%
% sFreq = the sampling rat. If empty, it will be inferrred
%
% Cowen 2023
min_duration_s = 0.04;
threshold_type = 'uV'; %'sd'
threshold = 35; 
intervals_to_ignore = [];
% default filters. You can pass in your own.
rip_filt_obj = designfilt('bandpassiir','FilterOrder',14, 'HalfPowerFrequency1',140,'HalfPowerFrequency2',200,'SampleRate',sFreq);
pre_rip_filt_obj = designfilt('bandpassiir','FilterOrder',14, 'HalfPowerFrequency1',70,'HalfPowerFrequency2',90,'SampleRate',sFreq);
theta_filt_obj = designfilt('bandpassiir','FilterOrder',14, 'HalfPowerFrequency1',5,'HalfPowerFrequency2',12, 'SampleRate',sFreq);
PLOT_IT = false;

Extract_varargin;

% blank out bad intervals so that false rips are not detected.
for iR = 1:Rows(intervals_to_ignore)
    IX = D(:,1) >= intervals_to_ignore(iR,1) & D(:,1) <= intervals_to_ignore(iR,2);
    D(IX,:) = 0; % to prevent detection.
end
Dfilt        = filtfilt(rip_filt_obj, D(:,2));
Denv         = envelope(abs(hilbert(Dfilt)));
Dpreripfilt  = filtfilt(pre_rip_filt_obj, D(:,2));
Dpreripenv   = envelope(abs(hilbert(Dpreripfilt)));
Dthetafilt   = filtfilt(theta_filt_obj, D(:,2));
Dthetaenv    = envelope(abs(hilbert(Dthetafilt)));
ripple_index = Denv./Dpreripenv;

% GIX = ripple_index > 1.2; % should be above moderate gamma by a little.
% % Do an initial filter.
% Denv(~GIX) = 0;
[RIP.above_times_uS, RIP.below_times_uS, RIP.above_IX, RIP.below_IX] = find_intervals([D(:,1) Denv],threshold,nan,min_duration_s*1e6);
% clean up rippls that are just on the edige of the recording period. 
if Rows(RIP.above_times_uS) < 3
    RIP.above_times_uS = [];
end

if ~isempty(RIP.above_times_uS)
    if RIP.above_times_uS(1) < D(1,1)+1e6
        RIP.above_times_uS(1,:) = [];
    end

    if RIP.above_times_uS(end) > D(end,1)-1e6
        RIP.above_times_uS(end,:) = [];
    end
end

if nargout > 1
    [RIP_INFO.RF,RIP_INFO.RIPS] = Ripple_features([D(:,1:2) Dfilt], RIP.above_times_uS);
end
% Dtheta_pow = envelope(abs(hilbert(filtfilt(rip_filt_obj, D(:,2)))));
if PLOT_IT
    if Rows(RIP.above_times_uS) > 10
        tminutes = D(:,1)/60e6;

        figure
        plot(tminutes,D(:,2))
        hold on
        plot(tminutes,Dpreripfilt)
        plot(tminutes,Dfilt)
        plot(tminutes,Denv)
        if ~isempty(RIP.above_times_uS)
            plot(RIP.above_times_uS(:,1)/60e6,ones(size(RIP.above_times_uS(:,1))),'g>')
            plot(RIP.above_times_uS(:,2)/60e6,ones(size(RIP.above_times_uS(:,1))),'r<')
        end
        yyaxis right
        plot(tminutes,ripple_index);
        xlabel('minutes')

    end
end