function [M, x_axis, A_msec, h ] = PETH_raster(spike_times_ts,alignments_ts,bin_and_inc_size_msec,time_before_msec,time_after_msec,plot_type)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% formerly align_spike_times.
% Create a PETH with a raster or aligned rate map of trials above it.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%function [M, A_msec, x_axis] = PETH_raster(spike_times_ts,alignments_ts,bin_and_inc_size_msec,time_before_msec,time_after_msec,option)
% TIMESTAMPS ARE ASSUMED TO BE IN 1/10000 of a second. (OLD CONVENTION)
% INPUT:
%  spike_times_ts   - a ts object or a vector of spike times or a tsd
%  object TIMES ASSUMED TO BE IN 0.1 msec!!
%  alignments_ts    - a ts object or vector of times from which spike_times_ts should
%                   be aligned.TIMES ASSUMED TO BE IN 0.1 msec!!
%  bin_and_inc_size_msec - the bin size in the spike time matrix.
%  time_before_msec - time before the alignment
%  time_after_msec  - time after the alignment.
%  plot_type =
%
%
% OUTPUT:
%  M - a matrix with the spikes aligned
%  A - a cell array of spike times that are aligned with time 0 at the event time.
%  x_axis - the x axis of the plot
% if no output, then an aligned spike matrix is drawn. The gca is set to the top axis so you can
%   easily put a title on top.
%
% Cowen 2022
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 2/26/03 -- major checks and tweaks. It is more precise now.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 11/20/02
%error('This function is temporarily out of service until we can figure out why it does not produce a consistent baseline for the data (in the M variable). The problem may be in PC_plot_trialtypes.')
h = [];

if nargin < 6
    plot_type = [];
end

if isa(spike_times_ts,'ts')
    spike_times_ts = Data(spike_times_ts);
end

if isa(alignments_ts,'ts')
    alignments_ts = Data(alignments_ts);
end

if isempty(alignments_ts) || length(alignments_ts) == 1
    disp('No alignments or only one alignment specified.')
    M = []; A_msec=[]; x_axis=[];
    return
end
if iscell(spike_times_ts)
    for iN = 1:length(spike_times_ts)
        [M{iN}, x_axis, A_msec ] = PETH_raster(spike_times_ts{iN},alignments_ts,bin_and_inc_size_msec,time_before_msec,time_after_msec);
    end
    return
end
if any(isnan(alignments_ts))
    error('nans are in the alignments')
end

% Get rid of any nans - ignored trials.
% alignments_ts = unique(alignments_ts(~isnan(alignments_ts)));

% for sliding windows.
if length(bin_and_inc_size_msec) == 1
    increment_msec = bin_and_inc_size_msec;
    dt_msec = bin_and_inc_size_msec;
else
    increment_msec = bin_and_inc_size_msec(1);
    dt_msec = bin_and_inc_size_msec(2);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Align the timestamps by subtracting the point time from each record
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
A_msec = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The range is the start and end times of each bin.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add a little so things are centered on each bin.
alignments_ts = alignments_ts(:);
range_msec    = -(time_before_msec + increment_msec/2):increment_msec:(time_after_msec - increment_msec/2);
x_axis        = range_msec+dt_msec/2 ; % align so that the xaxis is at the CENTER of each bin (hence the 1/2 bin )

if isempty(spike_times_ts)
    disp('NO DATA')
    M = zeros(length(alignments_ts),length(x_axis));
    return
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The following are 2 methods to do the same thing. A kind of double check. In
% addition, sometimes one works faster, sometimes the other works faster.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[sorted_alignments_ts, six] = sort(alignments_ts);
if 0
    A_msec = Event_aligned_spike_times(spike_times_ts/10,sorted_alignments_ts/10,abs(range_msec(1)),range_msec(end)+dt_msec );
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Create a Q matrix around these new timestamps.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    M = Bin_ts_array(A_msec,[range_msec(:) range_msec(:) + dt_msec])';
    M = M(six,:);
else
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % The hopfully Fast way to do this...
    % Create a list of bin times that surrounds each event.
    % The range is the list of start times for each bin.
    % FIRST: ensure that the timest are ordered (but put trials in original
    % order at the end.)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    n_bins = length(range_msec);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % n_bins = ceil((time_after_msec+time_before_msec+dt_msec)/dt_msec);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    start_bins_msec = sorted_alignments_ts/10 + range_msec(1); % range_msec(1) should be negative so this is a subtraction.
    %start_bins_msec = start_bins_msec(find(start_bins_msec>0)); % Get rid of events that are incomplete.
    n_rows = length(start_bins_msec);
    bins_msec = repmat(start_bins_msec(:),1,n_bins) + repmat(([1:n_bins]-1)*increment_msec,n_rows,1);
    r = reshape(bins_msec,n_bins*n_rows,1);
    [st idx] = sort(r); % bin_ts_array requires numbers be sorted.
    [n,idx]  = sort(idx); % This gives you the indices in st that give you back r. (Reverse problem)
    % Bin the times
    V = Bin_ts_array({spike_times_ts(:)/10},[st(:), st(:) + dt_msec ]);
    % Old school THIS WORKS! but very slow. The above shoud work. The following is a sanity check.
    if 0 % This is not the problem. the binning is fine.
        count = 1;
        for ii = 1:length(st)
            V(count) = length(find( (spike_times_ts/10)>=st(ii) & spike_times_ts/10<(st(ii)+ dt_msec) ));
            count = count + 1;
        end
    end
    % SOrt things back to how they were.
    M = reshape(V(idx),n_rows,n_bins);
    M = M(six,:); % Sort back to the original order.
    if nargout > 2
        A_msec = Event_aligned_spike_times(spike_times_ts/10,alignments_ts/10,abs(range_msec(1)),range_msec(end)+dt_msec );
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot if no args passed.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout == 0 || ~isempty(plot_type)

    if isempty(A_msec)
        A_msec = Event_aligned_spike_times(spike_times_ts/10,alignments_ts/10,abs(range_msec(1)),range_msec(end)+dt_msec );
    end
    plot_PETH(M, x_axis, 'trial_spike_times', A_msec)
    xlabel('ms')
end


