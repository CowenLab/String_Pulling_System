function [SE_data ,SE_times_sec]= Create_waveform_matrix(window, spike_data, times_sec, nearness_thresh_msec,npoints)
%
% INPUT: window - thresholds to apply to the waveform. May either be a scalar or a vector of 2 elements
%        to make a window between which to limit peaks.
%        spike data  - the raw data a one dim vector
%        time_sec    - the times for each element in the vector.
%        nearness_thresh_msec - eliminate two events if they both happen within this window.
%
% OUTPUT: SE_data - each row in this matrix contains the waveform of one threshold crossing
%         SE_times_sec - the time of occurence of each waveform.
%

% cowen

sample_rate_hz = 1/mean(diff(times_sec));

npoints_thresh = sample_rate_hz/1000*nearness_thresh_msec;

if min(window) < 0
  reverse_polarity = 1;
else
  reverse_polarity = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find the spikes and get the waveforms for each one.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if reverse_polarity
  [time_indices,SE_data] = CR2SE_chg_width(-1*spike_data,min(abs(window)),...
    npoints,npoints_thresh);
else
  [time_indices,SE_data] = CR2SE_chg_width(spike_data,min(abs(window)),...
    npoints,npoints_thresh);
end  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If requested, eliminate the waveforms that go above a passed in threshold.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if length(window)==2
  i = find(max(SE_data') < max(abs(window)));
  SE_data = SE_data(i,:);
  time_indices = time_indices(i);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reverse the polarity again if necessary (if the threshold was negative).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if reverse_polarity
  SE_data = -1*SE_data;
end

if isempty(SE_data)
  disp(['No threshold crossings'])
else
  ncrossings = length(time_indices);
  disp ([ num2str(ncrossings) ' threshold crossings.' ])
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Use the mean as the baseline. This 
  % will then be subtracted off the waveform.
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  baseline = mean(SE_data,2); 
  SE_data  = SE_data - repmat(baseline,1,size(SE_data ,2));
  SE_times_sec    = times_sec(time_indices);
end
