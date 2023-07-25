function Resample_EEG(CR_files,new_sFreq,new_filename_postfix, interval_usec)
% function Resample_EEG(CR_files,new_rate,new_filename_postfix)
% 
% Open up all of the files in teh CR_files cell array, resample them, and then 
% re-save the data with the passed in postfix. Data is saved as a .mat file.
% A timestamp is saved with each record. Data is saved as a nX2 matrix with the 
% first column being a vector.
%
% IMPORTANTLY, the file will re-align all timestamps in all of the files so that 
%   they share the same start and end. This may mean that the start may not start
%   with interval_usec(1).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PREV_TIME_USEC = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Just load the timestamps and then find the timestamps that are
% in common to all files. Just load those times (some files will not have complete records.)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
intrvl = [0 inf];
[common_TS, sFreq] = Load_EEG_Block_Timestamps(CR_files{1},interval_usec);
for fc = 2:length(CR_files)
    [TimeStamps] = Load_EEG_Block_Timestamps(CR_files{fc},interval_usec);
    intrvl(1) = max([intrvl(1), TimeStamps(1)])
    intrvl(2) = min([intrvl(2), TimeStamps(end)])
    fprintf('.')
end 
new_timestamps_usec = intrvl(1):1e6/new_sFreq:intrvl(end);
for ii = 1:length(CR_files)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Find the common start and end times for all of the files
    % Load the data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [TIME_USEC, DATA, sFreq] = ReadCR_to_matrix(CR_files{ii}, interval_usec(1), interval_usec(end), new_timestamps_usec);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Make sure the samples are the same between files
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ii>1
        if length(PREV_TIME_USEC) ~= length(TIME_USEC)
            disp(['File length mismatch: ' CR_files{ii-1} ' ' CR_files{ii}])
        elseif ~all(PREV_TIME_USEC == TIME_USEC)
            disp(['Timestamp mismatch: ' CR_files{ii-1} ' ' CR_files{ii}])
        end
    end
    PREV_TIME_USEC = TIME_USEC;    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Save the data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [p,n,e] = fileparts(CR_files{ii});
    save(fullfile(p,[n new_filename_postfix '.mat']),'DATA','TIME_USEC')
    
    fprintf('.')
end