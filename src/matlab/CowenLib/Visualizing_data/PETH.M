function [p,hist_data,xdim_ts] = PETH(timestamps, alignments_ts, peth_duration_ts, binsize_ts, method_to_use)
% function [p,hist_data,xdim_ts] = PETH(timestamps, alignments_ts, peth_duration_ts, binsize_ts)
% COWEN :: THIS FUNCTION HAS BEEN SUPERCEDED BY PETH_RASTER
%
% Creates a peri event time histogram of spike centered on the center
% if the alignments_ts specified in 'alignments_ts'. 
% 
% INPUT
% timestamps = a vector of timestamps, ts object or ts array of spike times.
% alignments_ts  = A nX2 or nX1 matrix where n is the number of
%              observations(timestamps). If there are two columns,
%              then the PETH is centered in the middle of the times
%              specified by the start and end times. 
%              If the alignments_ts is a single column, the PETH is
%              centered on the timestamps in this column.
% peth_duration = length of the PETH (in ts). If peth duration is a vector of
%               2 elements, then the first element is considered the time 
%               before and the second element the time after the alignments_ts.
%
% binsize_ts = size of bins to use in histogram.
%
% OUTPUT:
%  if no output aruguements are provided, a plot is made.
%  p - an ordered number of events. To create a histogram, just run
%     hist on this list of events.
%
%  hist_data - the histogram. Plotting hist data is the peri-event time
%             histogram.
%  if 'mean_std' is the method, then this is a structure where
%     hist_data.counts 
%     hist_data.mean
%     hist_data.std
%   otherwise it's just the count per bin.
%  xdim_ts   - the x dimension of the histogram in ts(.1msec).
%
%  NOTE: future versions may want to have the option of anchoring the
%  PETH on the start or end of the interval instead of the center.
%
% COWEN :: THIS FUNCTION HAS BEEN SUPERCEDED BY PETH_RASTER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% cowen Thu Jan  6 14:49:51 2000
if nargin < 4
    binsize_ts = 1;
end
if nargin < 5
    method_to_use = 'mean_std';
end
warning('SOMETHING HAPPENED TO PETH. I DONT TRUST THE OUTPUT. USE ALIGN_SPIKE_TIMES')
if length(peth_duration_ts) == 2
    time_before_ts = peth_duration_ts(1);
    time_after_ts  = peth_duration_ts(2);
    peth_duration_ts = time_before_ts + time_after_ts;
else
    time_before_ts = ceil(peth_duration_ts/2);
    time_after_ts  = ceil(peth_duration_ts/2);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert ts objects to vectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isa(alignments_ts, 'ts')
    alignments_ts = Data(alignments_ts);
end
[r,c] = size(alignments_ts);
if r == 1 | c == 1
    alignments_ts = sort(alignments_ts(:));
end
[r,c] = size(alignments_ts);


if c == 1
    center_between_intervals = 0;
elseif c == 2
    center_between_intervals = 1;
else
    error('too many columns')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create a list of all the spikes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iscell(timestamps)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Make a monster timestamp list of all timestamps
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    D = [];
    for ii = 1:length(timestamps)
        D = [D; Data(timestamps{ii})];
    end
    D = sort(D(:));
else  
    if isa(timestamps,'ts')
        timestamps = Data(timestamps);
    end
    D = sort(timestamps);
    l = length(D) - length(unique(D));
    if l ~= 0;
        disp(['WARNING: ' num2str(l) ' Duplicate timestamps. Ignoring them.'])
        D = unique(D);
    end
    D = D(:);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create some new intervals that reflect the size of the PETH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if center_between_intervals
    v = ceil((peth_duration_ts - (alignments_ts(:,2) - alignments_ts(:,1)))/2);
    new_alignments_ts = [alignments_ts(:,1) - v, alignments_ts(:,2) + v];
else
    new_alignments_ts = [alignments_ts - time_before_ts, alignments_ts + time_after_ts];
end

PM = [];

for ii = 1:size(new_alignments_ts,1)
    if ~isempty(D)
        starttime = new_alignments_ts(ii,1); % start time.
        endtime = new_alignments_ts(ii,2); 
        ix1 = binsearch(D,starttime);
        ix2 = binsearch(D,endtime);
        PM = [PM;D(ix1:ix2)-starttime];
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% There will be some negative values because binseach finds the value
% <= starttime. As a result, it will grab the spike that occured
% before the starttime. To get rid of these events, we just have to
% eliminate the negative valuse.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = PM(find(PM>0)); % These are the ripples that occured at the beginning of the record
p = p(find(p<peth_duration_ts)); % These are the ripples that occured at the beginning of the record
p = sort(p);

xdim_ts = [-time_before_ts:binsize_ts:time_after_ts];

if nargout>1
    hist_data = hist(p,xdim_ts+time_before_ts);
end

% plot out the results.
if nargout == 0
    hist_data = hist(p,xdim_ts+time_before_ts);
    plot(xdim_ts,hist_data)
    xlabel('timestamps')
    ylabel('count')
end
