function [OUT] = LK_HVS_detector(LFP_data, sFreq, varargin)
% For a given LFP data, find High Voltage Spindles time windows (first output) and remove
% the HVS times from the data if more than one output is asked
% TO DO: Change the LFP input to a matrix with timestamps and data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define variables.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
thresh = 4500;
PLOT_IT = false;
Extract_varargin;

OUT = [];
LFP = LFP_data(:,2)*0.195; % making the LFP data a double and multiplying by the uV conversion 
OUT.t_uS = LFP_data(:,1);
% create filter for spindle detection and the control fq band
sp_freq = [13 18];
ctrl_freq = [10 13];
filts = SPEC_create_filters({sp_freq ctrl_freq}, sFreq);
% times
times_uS = (0:(length(LFP)-1))/sFreq;
times_uS = 1e6*times_uS(:);
%% Find spindles in data
% get the power envelope for the fq bands
pow_sp = abs(hilbert(filtfilt(filts{1},LFP)));
pow_ctrl = abs(hilbert(filtfilt(filts{2},LFP)));
% find intervals
hvs_sig = conv_filter(pow_sp-pow_ctrl,hanning(sFreq));
% times_uS = [0:length(OUT.t_uS)-1]';
[sp,not_sp,above_IX,below_IX] = find_intervals([times_uS,hvs_sig],thresh,[],[],2e6);
if PLOT_IT
    figure
    plot(times_uS/60e6, LFP);
    yyaxis right
    plot(times_uS/60e6, hvs_sig);
    % plot(LFP.t_uS/60e6, conv_filter(pow_sp-pow_ctrl,hanning(LFP.sFreq)));
    hold on
    plot(sp(:,1)/60e6,ones(size(sp(:,1))),'g>')
    plot(sp(:,2)/60e6,ones(size(sp(:,1))),'r<')
else
end
OUT.sp_times = sp;
OUT.nonsp_indicies = below_IX;
OUT.sp_indicies = above_IX;
OUT.threshold = thresh;
% OUT.filt_LFP = hvs_sig;

%% Restrict the data to the non spindle times
res_data = Restrict([times_uS LFP], not_sp(:,1), not_sp(:,2));
OUT.data = res_data(:,2);
OUT.res_t_uS = OUT.t_uS(below_IX,:);

