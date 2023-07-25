function [A A2] = Event_aligned_spike_times(spike_times, alignments, time_before, time_after )
%function [A A2] = Event_aligned_spike_times(spike_times,alignments,time_before,time_after )
% Returns the timestamps reecntered so that each time has the event center
% time subtracted from it.
% units are whatever you pass in.
%
% To create a PETH Raster plot with 10msec bins, simply do..
% bins = binned([startrange endrange],binsize)
% P = Bin_ts_array(A,bins).
%See Align_on_Events 
% cowen 2006
if isempty(spike_times) || isempty(alignments)
    A = [];A2 = [];
    return
end

time_before = abs(time_before); % incase they pass in a negative value.
%time_after  = abs(time_after);

A = cell(length(alignments),1);
% Remove timestamps that come before the first time and are after the last
% time to speed things up
ix1 = binsearch(spike_times,min(alignments)-2*time_before);
ix2 = binsearch(spike_times,max(alignments)+2*time_after);
if ix1<ix2
    spike_times = spike_times(ix1:ix2);
end
A  = cell(length(alignments),1);
for ii = 1:length(alignments)
    ast = spike_times - alignments(ii);
    %
    % Using binsearch instead of find is MUCH (at least 3x) faster.
    %
    b1 = binsearch(ast,-time_before);
    b2 = binsearch(ast, time_after); % Add a little extra to avoid cutting off some from the edge.
    
    if ast(b1) < -time_before
        b1 = b1+1;
    end
    
    if ast(b2) > time_after
        b2 = b2-1;
    end
        
    if b1 <= b2
        % Doing it this way is much faster than concatenating a matrix as
        % we go along. (as in the old Align_on_
        A{ii} = ast(b1:b2);
    end
end
if nargout == 2
    A2 = cell2mat(A);
end
