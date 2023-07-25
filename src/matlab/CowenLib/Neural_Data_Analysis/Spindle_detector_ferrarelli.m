function [spindle_times_sec, PARAM, F] = Spindle_detector_ferrarelli(LFP,sFreq,sleep_intervals,PARAM)
% INPUT
%
% npoints x 2 col matrix. 1st col is time in seconds. 2nd col is the EEG
% data. Presumed to be in uV.
% sFreq = the sampling frequency of the data.
% sleep_intervals = the start and end times of each contiguous block of
% sleep Seconds.
% params: parameters for detection - a structure. Will change between
% subjects.
% Wrapper for.... % function [detection,spindle_times_sec,spindle_recs,RectifiedData] = ferrarelli_spindle_detection(C3,fs,sleep,age)
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
    PARAM.species = 'mice';
end
target_fq = floor(mean(PARAM.Sigma_range));
% target_fq = 11;

features = [];
% sleep_intervals = Interval_merge(sleep_intervals);
% The original code wants cell arrays for each interval. So be it...
stage = zeros(size(LFP(:,1)));
for iInterval = 1:Rows(sleep_intervals)
    IX = LFP(:,1) >= sleep_intervals(iInterval,1) & LFP(:,1) <= sleep_intervals(iInterval,2);
    stage(IX) = 2;
end
[detection,spindle_times_sec,spindle_recs] = ferrarelli_spindle_detection(double(LFP(:,2)),sFreq,stage, PARAM.species);
% the above algorithm seems to also spindle_times_sec
dur_s = spindle_times_sec(:,2) - spindle_times_sec(:,1);

if nargout > 2
    F.fqs = 1:.25:50;
    for ii = 1:Rows(spindle_times_sec)
        L = Restrict(LFP,spindle_times_sec(ii,:));
        F.psd(ii,:) = pwelch(L(:,2),[],[], F.fqs,sFreq);
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Wrapper for.... % function [detection,spindle_times_sec,spindle_recs,RectifiedData] = ferrarelli_spindle_detection(C3,fs,sleep,age)
% This detector expects that the data is JUST sleep so only pass it in
% % contiguous sleep periods.
% all_recs = []; spindle_times_sec = [];
% for iInterval = 1:Rows(sleep_intervals)
%     IX = LFP(:,1) >= sleep_intervals(iInterval,1) & LFP(:,1) <= sleep_intervals(iInterval,2);
%     recids = find(IX);
%     start_time_s = LFP(recids(1),1);
%     nLFP = double(LFP(IX,2));
%     stage = ones(sum(IX),1)*2;
%     [detection,tmp_spindle_times_sec,spindle_recs] = ferrarelli_spindle_detection(nLFP,sFreq,stage,'rats');
%     all_recs = [all_recs;spindle_recs + recids(1)];
%     spindle_times_sec = [spindle_times_sec;tmp_spindle_times_sec + start_time_s];
% end

if nargout == 0
    figure
    plot(LFP(:,1),LFP(:,2))
    hold on
    plot(spindle_times_sec(:,1),zeros(size(spindle_times_sec(:,1))),'g>')
    plot(spindle_times_sec(:,2),zeros(size(spindle_times_sec(:,1))),'r<')
    
end