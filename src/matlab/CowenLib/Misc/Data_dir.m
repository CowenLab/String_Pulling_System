function p = Data_dir()
% Replace the file below with the correct data directory.

if exist('F:\Data\Effort_Reward','dir')
    p = 'F:\Data';
elseif  exist('F:\Nitz_Spiral','dir')
    p = 'F:\';
elseif  exist('C:\Data','dir')
    p = 'C:\Data';
elseif  exist('C:\Cowen\Data','dir')
    p = 'C:\Cowen\Data';
elseif  exist('G:\Data','dir')
    p = 'G:\Data';
else
       error([mfilename ': Could not find DATA directory. ' p ])
end