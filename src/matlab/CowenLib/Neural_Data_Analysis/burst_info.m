function I = burst_info(spike_time,burst_msec_threshold)
% Determine various parameters about the spikes - 
%  first spike in a burst
%  members of a single burst
%  
% INPUT: a nx2 matrix of time (msec), phase (0 - 1 (360 degrees)
% OUTPUT: a structure of useful information.
%  the burst_grp gives a unique id to each burst - id of 0 means that the
%  spike was NOT a member of a burst.
%
%
if nargin < 2
    burst_msec_threshold = 12; % msec - spikes within this interval are lumped into one burst.
end
diffTime = [0;diff(spike_time(:))];

group_count = 1;
time_count = 1;
I.first_in_burst_grp = zeros(size(diffTime));
I.last_in_burst_grp = zeros(size(diffTime));
I.burst_grp = zeros(size(diffTime));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find the spike bursts.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while time_count < length(diffTime)
    if diffTime(time_count) < burst_msec_threshold*1000
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %        if diffTime(time_count + 1)< burst_msec_threshold
        % there must be at least 3 spikes to call this a burst.
        %       end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        I.first_in_burst_grp(time_count) = group_count;
        I.burst_grp(time_count) = group_count;
        while diffTime(time_count) < burst_msec_threshold*1000 & time_count < length(diffTime)
            I.burst_grp(time_count) = group_count;
            time_count = time_count + 1;
        end
        I.last_in_burst_grp(time_count) = group_count;
        group_count = group_count + 1;
    end
    time_count = time_count + 1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
I.nspikes_per_burst = histcounts(I.burst_grp,unique(I.burst_grp));
