function [SLEEPIX, START_END_IX] = sleep_intervals(V, threshold, minimum_duration_in_samples)
% determine start and end times and indices of sleep intervals. Omit
% intervals that do not last longer than minimum_duration.
%
% INPUT: V = measure of sleep with bigger indicating poorer sleep.
%  threhold = BELOW this means sleeping. above this means not sleeping
%  minimum_duration_in_samples = if duration of an interval is <
%  minimum_duration_in_samples then delete this interval. 
%
% OUTPUT
%
% Cowen 2018
%

% threshold = 3.5;
% minimum_duration_in_samples = 3.5;
% V = [0 0 3 10 10 10 2 2 10 10 1 1 1 1 0 0 0];
%    x x x          x x       x x x x x x x 
V = V(:);

SLEEPIX = V < threshold;

d = diff([0; SLEEPIX]);

if SLEEPIX(end) == 1 
    d(end) = -1;
end

start_ix = find(d ==1);
end_ix   = find(d == -1) - 1;

START_END_IX = [start_ix(:) end_ix(:)];

durations = START_END_IX(:,2) - START_END_IX(:,1);

BADIX = durations < minimum_duration_in_samples;

START_END_IX(BADIX,:) = [];
SLEEPIX = zeros(size(SLEEPIX));

for iR = 1:Rows(START_END_IX)
    SLEEPIX(START_END_IX(iR,1):START_END_IX(iR,2)) = 1;
end
