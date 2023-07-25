function S = Time_string(tstamp)
%
% create a string in HH:MM:SS format 
%
% INPUT: a timestamp
% OUTPUT: a string in HH:MM:SS.ss notation
% 
%function Time_string(tstamp)

% cowen Sat Apr 10 11:53:23 1999

[ S, Err] = sprintf('%d:%d:%2.4f', Timestamp_to_hms(tstamp));

