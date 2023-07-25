function d = eeg_dir(session_string)
%function d = eeg_dir(session_string)
%
% pass in a session string (e.g. 7887_32) and this function will return the
% associated directory that contains the eeg data.
%
if exist('E:\Predictive_Capacity_Backup\')
    % load from the raw data dir.
    part_path = fullfile('E:\Predictive_Capacity_Backup',session_string(1:4),[session_string 'r']);
    dout = dir(fullfile(part_path,'200*'));
    d = fullfile(part_path,dout.name)
else exist('H:\Cowen\Data\')
    d = pwd;
    %else
    %    eeg_root_dir = 'C:\Predictive_Capacity_EEG\';
    %    d = fullfile(eeg_root_dir,[session_string 'r']);
end
