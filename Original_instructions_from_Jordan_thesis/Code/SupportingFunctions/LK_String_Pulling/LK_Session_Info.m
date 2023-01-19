function SES = LK_Session_Info(sesdir)
% Get general information for this session based on the directory path and
% things.
% Cowen 2020
if nargin < 1
    sesdir = pwd;
end
[tmp,SES.session_str] = fileparts(sesdir);
SES.session = str2double(SES.session_str);
[~,SES.rat_str] = fileparts(tmp);
SES.rat = str2double(SES.rat_str(4:end));
SES.title_str = sprintf('%s_Ses%s',SES.rat_str,SES.session_str);
SES.pwd = pwd;