function [spike_peak_idx,wave_data] = CR2SE_chg_width(cr, threshold, npoints, nearness_thresh)
% INPUT
%
%        cr - the continuous record
% threshold - the threshold for an event
% npoints   - number of points in front of and behind the peak 
%             format: [front, behind] 
%             If a scalar is passed, 20% of those points are put in front
%             and the remaining 80% in back.
% nearness_thresh - Events that occur within this window range are treated as 
%                 single events. This is useful if there are spikes that have two
%                 humps close by-- so that they don't get counted twice. The 
%                 number of points will depend on the sampling rate. For instance, 
%                 if you want a window of 1msec and your sampling rate is 44100, 
%                 then the npoints is ...
%                        44100samp/1sec * 1sec/1000msec * 1msec = 44 points.
%                 The first event is the one that is taken
%
% OUTPUT
% 
%  spike_peak_idx   - indices in cr that point to the peak of the waveform.
%  wave data        - the waveforms for each index 

% cowen 
% Modified from batta.
if nargin == 2 
  npoints = 32;
end

% Make the data vector a row vector if it's not already.
if(size(cr,1) > 1)
  cr = cr';
end

if 0
  d1 = [0 diff(cr)];
  d  = [diff(cr) 0];
  
  cr1 = [cr 0];
  cr2 = [0 cr];
  
  cross_points = find(cr1 > threshold & cr2 < threshold);
  peak_points = find(d1 > 0 & d < 0);
else
  % Much more memory efficient. Hopefully as fast.
  diffs  = [0 diff(cr) 0];
  cross_points = find([cr 0] > threshold & [0 cr] < threshold);
  peak_points = find(diffs(2:end) > 0 & diffs(1:end-1) < 0);
end

spike_peak_idx = peak_points(FindAlignNext(peak_points, cross_points))';

if nargin == 4
  % eliminate spikes that closely follow threshold crossings.
  d = [nearness_thresh+1; diff(spike_peak_idx)];
  spike_peak_idx = spike_peak_idx(find(d > nearness_thresh));
end

if ~isempty(spike_peak_idx)
  if length(npoints) == 2
    points_in_front = npoints(1);
    npoints = sum(npoints);
  else
    points_in_front = round(npoints*.3);
  end    
  nspikes = length(spike_peak_idx);
  % the following is a matrix of indices to the raw data for the waveforms.
  sp_point = repmat(spike_peak_idx, 1, npoints) + repmat(([1:npoints] - points_in_front), nspikes, 1);
  % Get rid of the traces that go beyond the sampling area (those that are cut off at the end of the recording)
  % and those that have beginnings before the sampling area (those that start before record is turned on).
  if 0
    % less efficient
    [i,j] = find(sp_point(:,end)>length(cr) | sp_point(:,1)<1);
    sp_point(i,:)     = [];
    spike_peak_idx(i) = [];
  else
    % more efficient
    [i,j] = find(sp_point(:,end)<length(cr) & sp_point(:,1)>1);
    sp_point       = sp_point(i,:);
    spike_peak_idx = spike_peak_idx(i);
  end
  wave_data = cr(sp_point);
else
  spike_peak_idx   = [];
  wave_data        = [];
end

