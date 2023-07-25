function Print_time(start_time, end_time)
%function Print_time(start_time, end_time)
% Print out the begin and end time to the screen.
%
% INPUT: start and end time in timestamps
% OUTPUT: none. Simply does a fprinf of the times passes in.

fprintf('Begin at ts %d, %d:%d:%d:%d \nEnd at   ts %d, %d:%d:%d:%d \n\n ',start_time,...
    Timestamp_to_hms(start_time),end_time, ...
    Timestamp_to_hms(end_time));

