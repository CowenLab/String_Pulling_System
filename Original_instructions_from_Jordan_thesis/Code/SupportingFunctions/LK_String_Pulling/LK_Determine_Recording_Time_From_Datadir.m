function [daystring, theday] = LK_Determine_Recording_Time_From_Datadir(ddir)
% Extract recording day from the name of the recording direcotry.
% If nothing specified, assume the recording directory is the *_processed
% directory.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 1
    ddir = LK_tfile_dir;
    [~,ddir] = fileparts(ddir);
end
s = split(ddir,'_');
str = [s{2} s{3}];
theday = datenum(str,'yymmddHHMMSS');
daystring = datestr(theday);