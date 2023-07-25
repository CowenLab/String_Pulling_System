function intervals = Remove_duplicate_intervals(intervals)
% given an n x 2 matrix of start and end times, remove intervals in which
% the preceding interval encompases entirely a subsequent interval or if
% the next interval starts WITHIN the current interval but ends later. in
% that case, create a new interval that starts with the first but ends with
% the end of the second.
%
%Cowen 2016.
%
if nargin == 0
    % Test
    intervals = [0 .9; 1 4; 1.1 4; 1 4; 2 3; 1 5; 5.5 10; 7 11; 6 12; .4 .6];
    intervals
end
intervals = sortrows(intervals);
% % Find intervals contined within larger intervals.
% IX = intervals(2:end,1) >= intervals(1:end-1,1) & intervals(2:end,2) <= intervals(1:end-1,2) ;
% while(any(IX))
%     intervals(find(IX) + 1,:) = [];
%     IX = intervals(2:end,1) >= intervals(1:end-1,1) & intervals(2:end,2) <= intervals(1:end-1,2) ;
% end
% intervals = floor(intervals);

BIX = false(Rows(intervals),1);

for ii = 1:(Rows(intervals)-1)
    % The next interval has an end time that is later than the interval of
    % the previous interval but starts at or within the previous interval.
    % In this case, replace the interval with a new interval and delete the
    % current interval.
    % If the start time of the next interval is WITHIN the present interval
    % This should not pass.
    if intervals(ii+1,1) >= intervals(ii,1) && intervals(ii+1,1) <= intervals(ii,2)
        % then set the end interval as the max of the e
        BIX(ii) = true;
        intervals(ii+1,1) = intervals(ii,1);
        intervals(ii+1,2) = max(intervals(ii:(ii+ 1),2));
    end
end
intervals = intervals(~BIX,:);
