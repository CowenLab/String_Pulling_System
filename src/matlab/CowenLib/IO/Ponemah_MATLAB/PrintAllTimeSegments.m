% Prints the start/end Local (Experiment) times of all data segments across
% all subjects/channels

%% User Input - Enter the Experiment path
szExpPath = 'C:\Ponemah_Data\Exp_1Subj_ECG_BP_Scheduled';
%szExpPath = 'C:\Ponemah_Data\Exp_1Subj_EEG_EMG_SignalStrength_Continuous';
%szExpPath = 'C:\Ponemah_Data\Exp_3Subj_ECG_BP_Continuous';

%% Get Experiment database
[~,szExpName,~] = fileparts(szExpPath);
szExpDatabase = [szExpPath, '\', szExpName, '.PnmExp'];

%% Load Ponemah6xExtractor Assembly to interpret the database
[mFilePath,name,ext] = fileparts(mfilename('fullpath'));
NET.addAssembly(strcat(mFilePath, '\Ponemah6xExtractor.dll'));

%% Retrieve subjects from the Experiment Database
subjects = Ponemah6xExtractor.Ponemah6XExtractor.GetPonemahSubjects(szExpDatabase);

%% Formatting for output to the screen
formatTitleStr = '%15s     %-10s';
formatValueStr = '%12s          %-10s\n';
titleStr = sprintf(formatTitleStr, 'Channel Id', 'Channel Label');

%% Step through all subjects 
for subjIdx=0:subjects.Count-1
    fprintf('\nSubject:  %s\n', char(subjects.Item(subjIdx).Name));     % Display Subject Name
    % Retrieve all channels for the subject
    channels = subjects.Item(subjIdx).Channels;
    disp(titleStr);
    % Step though each channel
    for chanIdx=0:channels.Count-1
        chan = channels.Item(chanIdx);
        fprintf(formatValueStr, int2str(chan.SubjectChannelId), char(chan.Label)); % Display Id and Label
        % get segments 
        [startTimes, endTimes] = GetTimeSegmentsLocal(szExpPath, channels.Item(chanIdx).SubjectChannelId);
%        [startTimes, endTimes] = GetTimeSegmentsUtc(szExpPath, channels.Item(chanIdx).SubjectChannelId);
        for sIdx=1:startTimes.Length
            fprintf('                %-25s  %-25s\n', char(startTimes(sIdx).ToString), char(endTimes(endTimes.Length).ToString));
        end
    end
end