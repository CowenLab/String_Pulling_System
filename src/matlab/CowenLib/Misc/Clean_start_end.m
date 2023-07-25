function [times1, times2] = Clean_start_end(times, min_diff)
% Merge intervals that close together where the closeness
% is specified by min_diff. 
%
% INPUT: times - nx2 start and end time matrix
%        min_diff_ts - the minimum difference between
%        the two times to be tolerated. Stuff less than this will be
%        merged.
%
% OUTPUT: times - the new times.

% cowen
d_times = times(:,2) - times(:,1);
idx = find (d_times > min_diff);
start_times = times(idx,1);
end_times = times(idx,2);

if nargout == 1;
    times1= [start_times(:) end_times(:)];
elseif nargout == 2
    times1 = start_times(:);
    times2 = end_times(:);
end

