function    [S M]= Sliding_stats(x,y,dt,shift, type); 
% Compute stats at intervals of x of the datapoints in y 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT
%   x = 
%   y = 
%   dt = 
%   shift = 
% OUTPUT
%   S.mean
%   S.median
%   S.std
%   S.min
%   S.max
%   S.intervals - n x 2 where col1 is the start time and col 2 is the end time of each interval.
%     If the last interval cannot be made with the specified size dt, then it is dropped
%
% Output is the stats from starttime to times LESS than endtime in the intervals.
% NOTE!: If the last interval cannot be made exactly of size dt, this interval is ignored.
%
% cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargout < 5
    type = 'normal';
end

start_times = x(1):shift:(x(end) - dt + 1);

end_times = start_times + dt - 1;
%end_times(end) = x(end);
end_times = end_times - eps; % Subtract a little so the intervals don't completely overlap in the
% case that there is a point exactly on the end time.
S.intervals = [start_times(:) end_times(:)];
switch type
case 'normal'
for ii = 1:length(start_times)
    idx = find(x >= start_times(ii) & x <= end_times(ii));
    S.mean(ii)   = mean(y(idx));
    S.median(ii) = median(y(idx));
    S.std(ii)    = std(y(idx));
    S.min(ii)    = min(y(idx));
    S.max(ii)    = max(y(idx));
    if nargout == 2 
        % calculate the mode
    end
end
case 'circular'
    disp('NOT IMPLEMENTED YET')
otherwise
    error('strange type')
end

if end_times < x(end)
    disp('WARNING: End time truncated.')
end
