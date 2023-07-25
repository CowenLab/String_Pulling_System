function [ph, ThetaPhaseTimes,PhasesPerCycle,bad_peak_start_times,bad_peak_end_times] = ...
    Phase_detector(S, CR, varargin)
% [ph, PeaksTimes,TroughsTimes,ZeroUpTimes,ZeroDownTimes,PhasesPerCycle] = Phase_detector(S, CR, TStart, TEnd)
%
% Computes the phase of CR at each timestamp in the ts objects
% contained in S (or S could be a vector of timestamps or a single ts
% object)
%
% INPUTS:
% S:              vector of timestamps, 
% CR:             n x [time data] matrix.
% OPTIONAL PARAMTERS: Pass in thus 'TStart', 100203,'TEnd',2030030
%
%
% OUTPUTS: 
%     phase.time - the timestamps in the spike train.
%     phase.phase_id - an integer from 1-4. Each cycle is divided in 4 sections and phase ID
%                   corresponds to each of these segments.
%     phase.quarter_phase_time - Time of the nearest peak, zero cross, or trough.
%     phase.phase_count - Count of the phase (4 increments per phase then it starts again with a 1).
%     phase.cycle_count - Count of the cycles(4 counts per cycle.) starting from 1.
%     phase.ph_count_linked_to_phase - interpolated phase count. 
%     phase.interp_phasetime - the interpolated time (ts). Finds the spike time and then add 
%     phase.phase_angle - a number from 0 to 1 that specifies the phase angle (0 - 360 degrees). I other words, 0
%                         is the peak of theta. Convert to radians by multiplying by 2pi.
%
%     S - the new ctsa spikes after getting rid of non-theta intervals.
%     ThetaPhaseTimes:The times of the peak, trough and zero crossings (in .1 msec)
%                 A 2D matrix where Col 1 is timestamp and Col 2 is the phase
%                 Phase: 1=peak, 2=zero down, 3= trough, 4= zero up nan = non theta.


% cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pass in good data or I will barf.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if 0
if Find_start(S) < StartTime(CR)
    error('First spike occurs before the first EEG record. Restrict the spike data and try again')
end

if Find_end(S) > EndTime(CR)
    error('Last spike occurs after the last EEG record. Restrict the spike data and try again')
end

end
% Get rid of cycles that had an interval longer or shorter than these two
% parameters.
bad_peak_start_times = [];
bad_peak_end_times = [];
max_peak_interval_msec = [];
min_peak_interval_msec = [];
PhasesPerCycle = 4; % This is hard wired for now.

Extract_varargin

% Find the peaks, troughs and the zero crossings in the data
[PeaksIdx,TroughsIdx,ZeroUpIdx,ZeroDownIdx] = Find_peaks_troughs_zeros(CR(:,2));
disp('Found peaks and troughs')
% Create a matrix that contains an identifier for each point in a theta
% cycle (1= peak, 2= zero down, 3 = trough, 4, rising zero)
PeaksTimes = CR(PeaksIdx,1);
TroughsTimes = CR(TroughsIdx,1);
ZeroUpTimes = CR(ZeroUpIdx,1);
ZeroDownTimes = CR(ZeroDownIdx,1);

len = length( [PeaksIdx(:); TroughsIdx(:); ZeroUpIdx(:); ZeroDownIdx(:)] );
ThetaPhaseTimes   = ones(len,2)*nan;
% PEAKS (they are all at 1)
ThetaPhaseTimes(1:length(PeaksIdx),1) = PeaksTimes;
ThetaPhaseTimes(1:length(PeaksIdx),2) = 1;
% DOWNWARD (2)
the_start = length(PeaksIdx) + 1;
the_end = the_start + length(ZeroDownIdx) - 1;
ThetaPhaseTimes(the_start:the_end,1) = ZeroDownTimes;
ThetaPhaseTimes(the_start:the_end,2) = 2;
% TROUGHS (3)
the_start = the_end + 1;
the_end = the_start + length(TroughsIdx) - 1;
ThetaPhaseTimes(the_start:the_end,1) = TroughsTimes;
ThetaPhaseTimes(the_start:the_end,2) = 3;
% UPWARD (4)
the_start = the_end + 1;
the_end = the_start + length(ZeroUpIdx) - 1;
ThetaPhaseTimes(the_start:the_end,1) = ZeroUpTimes;
ThetaPhaseTimes(the_start:the_end,2) = 4;
% Order by time
ThetaPhaseTimes = sortrows(ThetaPhaseTimes);

if 0
if Find_start(S) < ThetaPhaseTimes(1,1)
    error('First spike occurs before the first THETAPHASE record. Restrict the spike data and try again')
end

if Find_end(S) > ThetaPhaseTimes(end,1)
    error('Last spike occurs after the last THETAPHASE REC. Restrict the spike data a little more and try again')
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
% Get rid of Spike time data and Phase Time Data falling between 
% peaks that don't meet a minimum or maximum criteria.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
spikecnt = 0;
total_spikes = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
% This whole section should probably be trashed or relegated to another
% function that is called before or after this function is called.
% That function would filter out spikes that occur during non
% theta periods.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

if ~isempty(max_peak_interval_msec) | ~isempty(min_peak_interval_msec)
    d_idx = [];
    peak_times = floor(ThetaPhaseTimes(find(ThetaPhaseTimes(:,2)==1),1));
    d_msec          = [diff(peak_times); inf]/10;
    if ~isempty(min_peak_interval_msec)
        d_idx     = find(d_msec < min_peak_interval_msec);
    end
    
    if ~isempty(max_peak_interval_msec)
        d_idx      = [d_idx; find(d_msec > max_peak_interval_msec)];
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    % Erase the peaks that are not within a valid interval, for instance, 
    % around 100msec for theta and store the CR(:,1) in that area
    % so that the phase information can be set to nan later on. 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    bad_peak_start_times = peak_times(d_idx);
    extr_peak_times = [ peak_times; inf];
    bad_peak_end_times   = extr_peak_times(d_idx+1);
    good_peak_start_times = [peak_times(1)-1;bad_peak_end_times];
    good_peak_end_times = [bad_peak_start_times;peak_times(end)];
    idx = find((good_peak_start_times  - good_peak_end_times) <0);
    good_peak_start_times = floor(sort(good_peak_start_times(idx)+1));
    good_peak_end_times = floor(sort(good_peak_end_times(idx)-1));
    
    for ii = 1:length(S)
        total_spikes = total_spikes + length(S{ii});
        invalid_spikes{ii} = Restrict(S{ii},bad_peak_start_times,bad_peak_end_times);
        invalid_spikes{ii} = ts(unique(S{ii}));
        spikecnt = spikecnt + length(S{ii});
    end
    idx = [];
    for ii = 1:length(bad_peak_start_times)
        idx = [idx; find(ThetaPhaseTimes(:,1) >= bad_peak_start_times(ii) ...
                & ThetaPhaseTimes(:,1) < bad_peak_end_times(ii))];
    end
    ThetaPhaseTimes(unique(idx),2) = nan;
    
    if length(bad_peak_end_times) | length(bad_peak_start_times)
        disp(['Removed ' num2str(length(bad_peak_end_times))  ' (' num2str(100*(length(bad_peak_end_times)/length(peak_times))) '%) cycles and ' num2str(total_spikes-spikecnt) ' (' num2str(100*(1-(spikecnt/total_spikes))) '%) spikes.']);
    end
end

PeakTimes = ThetaPhaseTimes(find(ThetaPhaseTimes(:,2)==1),1);
nTotalSpikes = 0;
for iC = 1:length(S)
    nTotalSpikes = nTotalSpikes + length(S{iC});
end
ph = [];
for iC = 1:length(S)
    s               = S{iC}; % Spike Timestamps
    phase{iC}       = zeros(size(s));
    phasetime{iC}   = zeros(size(s));
    interp_phasetime{iC}   = zeros(size(s));
    phasecount{iC}  = zeros(size(s));    
    ph_count_linked_to_phase{iC}  = zeros(size(s));    
    phaseangle{iC}  = zeros(size(s));
    cyclecount{iC}  = zeros(size(s));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %pks = zeros(size(s));
    % I tried spline and often it would overshoot the maxima 1 or -1. Cubic does not.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %ph{iC} = interp1(ThetaPhaseTimes(:,1),ThetaPhaseTimes(:,2),s,'cubic');
    % binsearch to find the closest value in D that corresponds to the 
    % timestamp in s
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    for ii = 1:length(s)
        % Find closest value.
        %[minval, idx] = min(abs(ThetaPhsaseTimes(:,1) - s(ii)));
        idx                = binsearch(ThetaPhaseTimes(:,1),s(ii)); % Find the nearest peak, trough
                                                      % or zero that is closest to the timestamp  in s.
        phasecount{iC}(ii) = idx;
        if s(ii) > ThetaPhaseTimes(idx,1)
            % interpolated index of the phase count (4/cycle).
            % ThetaPhaseTimes are the times of the 4 divisions of each theta cycle.
            ph_count_linked_to_phase{iC}(ii) = idx + (s(ii) - ThetaPhaseTimes(idx,1) )/(ThetaPhaseTimes(idx+1,1) - ThetaPhaseTimes(idx,1));
            interp_phasetime{iC}(ii) = ThetaPhaseTimes(idx,1) + ((s(ii) - ThetaPhaseTimes(idx,1) )/...
                (ThetaPhaseTimes(idx+1,1) - ThetaPhaseTimes(idx,1)))*(ThetaPhaseTimes(idx+1,1)-ThetaPhaseTimes(idx,1));
        else
            ph_count_linked_to_phase{iC}(ii) = idx-1 + (s(ii) - ThetaPhaseTimes(idx-1,1) )/(ThetaPhaseTimes(idx,1)- ThetaPhaseTimes(idx-1,1));
            interp_phasetime{iC}(ii) = ThetaPhaseTimes(idx-1,1) + ((s(ii) - ThetaPhaseTimes(idx-1,1) )/...
                (ThetaPhaseTimes(idx,1) - ThetaPhaseTimes(idx-1,1)))*(ThetaPhaseTimes(idx,1)-ThetaPhaseTimes(idx-1,1));
        end
        phase{iC}(ii)      = ThetaPhaseTimes(idx,2);
        phasetime{iC}(ii)  = ThetaPhaseTimes(idx,1);
        cyclecount{iC}(ii) = binsearch_floor(PeakTimes, s(ii));
        phaseangle{iC}(ii) = (s(ii) - PeakTimes(cyclecount{iC}(ii)))/(PeakTimes(cyclecount{iC}(ii)+1) ...
            - PeakTimes(cyclecount{iC}(ii)));
    end
    %ph = [ph; ones(length(s),1)*iC phaseangle{iC} phasetime{iC} phasecount{iC} cyclecount{iC} ph_count_linked_to_phase{iC}];
    %ph{iC} = [phaseangle{iC} phasetime{iC} phasecount{iC} cyclecount{iC} ph_count_linked_to_phase{iC} interp_phasetime{iC} ];
    ph{iC}.time = s;
    ph{iC}.phase_id = phase{iC};
    ph{iC}.quarter_phase_time = phasetime{iC};   % Time of the nearest peak, zero cross, or trough.
    ph{iC}.phase_count = phasecount{iC};         % Count of the phase (4 increments per phase).
    ph{iC}.cycle_count = cyclecount{iC};         % count of the cycles
    ph{iC}.ph_count_linked_to_phase = ph_count_linked_to_phase{iC};
    ph{iC}.interp_phasetime = interp_phasetime{iC};
    ph{iC}.phase_angle = phaseangle{iC};
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %    ph{iC} = tsd( s, ...
    %        [phase{iC} phaseangle{iC} phasetime{iC} phasecount{iC} cyclecount{iC}]);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % plot some things....
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if 0
        figure
        plot(Range(CR,'ts'),ThetaPhaseTimes(:,1)./max(ThetaPhaseTimes(:,1)),'ro')
        hold on
        plot(s,ph{iC}./max(ThetaPhaseTimes(:,2),'ro'))
        plot(Range(CR,'ts'),CR(:,2)/max(CR(:,2)),'c')
    end

end

