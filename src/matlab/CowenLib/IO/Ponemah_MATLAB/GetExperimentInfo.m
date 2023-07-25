%% GetExperimentInfo()
% Retrieves information from the Experiment database

% Inputs
%   szExpPath       the Experiment folder
%   fileId          value from fopen() to write output to file
%                   use 1 to display output on the screen
% e.g. GetExperimentInfo('C:\Ponemah_Data\Exp_1Subj_ECG_BP_Scheduled', 1);

function GetExperimentInfo(szExpPath, fileId)

%% Load Ponemah6xExtractor Assembly if not already loaded
if isempty(which('Ponemah6xExtractor.Ponemah6XExtractor'))
    [mFilePath,~,~] = fileparts(mfilename('fullpath'));
    NET.addAssembly(strcat(mFilePath, '\Ponemah6xExtractor.dll'));
end

%% Get Experiment database
[~,szExpName,~] = fileparts(szExpPath);
szExpDatabase = [szExpPath, '\', szExpName, '.PnmExp'];

%% Retrieve subjects from the Experiment Database
subjects = Ponemah6xExtractor.Ponemah6XExtractor.GetPonemahSubjects(szExpDatabase);

%% Formatting for output to the screen
formatTitleStr = '%15s     %-10s';
formatValueStr = '%12s          %-10s\n';
titleStr = sprintf(formatTitleStr, 'Channel Id', 'Channel Label');

%% Step through all subjects 
for subjIdx=0:subjects.Count-1
    fprintf(fileId, '\nSubject:  %s\n', char(subjects.Item(subjIdx).Name));     % Display Subject Name
    % Retrieve all channels for the subject
    channels = subjects.Item(subjIdx).Channels;
    % get segments for the first channel
    [startTimes, endTimes] = GetTimeSegmentsLocal(szExpPath, channels.Item(0).SubjectChannelId);
    if startTimes.Length > 0
        fprintf(fileId, '     Start Time:   %s\n', char(startTimes(1).ToString));
        fprintf(fileId, '     End Time:     %s\n', char(endTimes(endTimes.Length).ToString));
        fprintf(fileId, '     Num Segments: %d\n', startTimes.Length);
    else
        fprintf(fileId, '%s\n', '     No data available');
    end
    fprintf(fileId, '%s\n', titleStr);
    % Step though each channel
    for chanIdx=0:channels.Count-1
        chan = channels.Item(chanIdx);
        fprintf(fileId, formatValueStr, int2str(chan.SubjectChannelId), char(chan.Label)); % Display Id and Label
    end
end