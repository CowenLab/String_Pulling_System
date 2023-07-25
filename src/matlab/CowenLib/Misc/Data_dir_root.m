function root_data_dir = Data_dir_root();
%function Datadir();
% Return the data directory of the user.

if (exist('G:\Cowen\Data\','dir'))
    root_data_dir = 'G:\Cowen\Data\';
elseif (exist('E:\Cowen\Data\','dir')) % USB drive.
    root_data_dir = 'E:\Cowen\Data\';
elseif (exist('H:\Cowen\Data\','dir')) % USB drive.
    root_data_dir = 'H:\Cowen\Data\';
elseif (exist('C:\Cowen\Data\','dir'))
    root_data_dir = 'C:\Cowen\Data\';
elseif (exist('W:\Data','dir'))
    root_data_dir = 'W:\Data';
elseif (exist('I:\','dir'))
    root_data_dir = 'I:\';
else 
    
end
disp([ ' Data directory :  ' root_data_dir]);