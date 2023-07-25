function M = Timestamp_to_hms(timestamp)
% Convert timestamp to hh mm ss format
% Copied directly out of Wilson's iolib.c TimestampToString
%
% INPUT : Vector of timestamps
% OUTOUT matrix of hours min sec(and fractions of seconds)
%
%function s = Timestamp_to_hhmmss(timestamp)

% cowen Thu Apr 29 09:22:12 1999
hour = floor((timestamp./1e4)./3600) ;
min = floor((timestamp./1e4)./60 - 60.*hour);
sec = timestamp./1e4 - 60.*min - 3600.*hour;
M = [hour min sec]; 
