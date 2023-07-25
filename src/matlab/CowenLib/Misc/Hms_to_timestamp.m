function M = Hms_to_timestamp(hh,mm,ss)
% Convert hours mins and secs to a timestamp
%
% INPUT : hh, mm, ss
% OUTOUT : a timestamp
%
%function M = HMS_to_timestamp(hh,mm,ss)

% cowen Mon Jul  5 16:03:54 1999
M = hh*60*60*1e4+mm*60*1e4+ss*1e4;
