function GP = Get_Computer_Specific_Global_Vars(fname)
% Find documents directory.
% Attempts to load a matlab_analysis.ini file from this directory.
if contains(computer, 'PCWIN')
    user_dir = getenv('USERPROFILE');
    % Create a string to the "My Documents" folder of this Windows user:
    user_documents_dir = sprintf('%s\\My Documents', user_dir);
else
    % TODO: Put mac specific directory here. I don't know how to get this.
end
if nargin < 1
    ini_file = fullfile(user_documents_dir,'matlab_analysis.ini');
else
    ini_file = fname;
end
% Load the .ini file that has
if exist(ini_file,'file')
    GP = ini2struct(ini_file);
else
    GP.NO_INI_FILE_FOUND = [];
    disp(ini_file)
    error('no INI file found')
end
GP.ini_file = ini_file;
GP.user_documents_dir = user_documents_dir;