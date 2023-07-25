function [spindle_times_sec, PARAM, F] = Spindle_detector_wamsley(LFP,sFreq,sleep_intervals,PARAM)
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
if nargin < 4
    PARAM.min_dur_s = 0.5;
    PARAM.merge_thresh_s = 0.2;
    PARAM.Sigma_range = [10 15];
end
target_fq = floor(mean(PARAM.Sigma_range));
% target_fq = 11;

features = [];
sleep_intervals = Interval_merge(sleep_intervals);
% The original code wants cell arrays for each interval. So be it...
LFPs = cell(Rows(sleep_intervals),1);
for iInterval = 1:Rows(sleep_intervals)
    tmp =  Restrict(LFP,sleep_intervals(iInterval,:));
    LFPs{iInterval} = tmp(:,2);
end
[detection,spindle_times_sec,spindle_recs] = wamsley_spindle_detection(LFPs,LFP(:,2),sFreq,target_fq);
if nargout > 2
    F.fqs = 1:.25:50;
    for ii = 1:Rows(spindle_times_sec)
        L = Restrict(LFP,spindle_times_sec(ii,:));
        F.psd(ii,:) = pwelch(L(:,2),[],[], F.fqs,sFreq);
    end
end

if nargout == 0
    figure
    plot(LFP(:,1),LFP(:,2))
    hold on
    plot(spindle_times_sec(:,1),zeros(size(spindle_times_sec(:,1))),'g>')
    plot(spindle_times_sec(:,2),zeros(size(spindle_times_sec(:,1))),'r<')
    
end