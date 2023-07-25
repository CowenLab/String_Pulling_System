function d = Skydrive_directory()
% Find the skydrive directory for this user...
%
user = getenv('USERNAME');
d = fullfile('C:','Users',user,'SkyDrive','Documents');
if exist(d,'dir')
    return;
end
% For some reason, skydrive appends the computer name - sometimes.
d = fullfile('C:','Users',[user '.' getenv('COMPUTERNAME')],'SkyDrive','Documents');
if exist(d,'dir')
    return;
end
d = [];
