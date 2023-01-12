function E = LK_Load_Events_From_Excel(fname)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%e%%%%%%%%%%%%%%%
% Cowen 2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load event times.
[p,n,e] = fileparts(fname);
fname2 = fullfile(p,n,'.csv');
if ~exist(fname,'file')
    if exist(fname2,'file')
        disp('FOUND csv event file, not excel event file')
        E = readtable(fname2);
        E.EventID = categorical(E.EventID);
        return
    end
    E = [];
    return
end
E = readtable(fname,'Sheet','Event_times');
E.EventID = categorical(E.EventID);
E.t_uS = E.MinFromStart*60e6;