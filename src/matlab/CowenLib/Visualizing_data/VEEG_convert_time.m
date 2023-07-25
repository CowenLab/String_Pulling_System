function t = Veeg_convert_time(r)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert the time sent out from sptool to a real timestamp
% and to the HH:MM:SS time.
% INPUT: timestamp
% OUTPUT: structure of t.x1, t.x2, t.hms1, t.hms2
%  cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global GP

t.x1 = r.x1*10000 + GP.start_ts;
t.x2 = r.x2*10000 + GP.start_ts;
t.hms1 = time_string(t.x1);
t.hms2 = time_string(t.x2);

if ~isempty(r.peaks.x)
    t.peaks.x = r.peaks.x*10000 + GP.start_ts;
end

if ~isempty(r.valleys.x)
    t.valleys.x = r.valleys.x*10000 + GP.start_ts;
end
