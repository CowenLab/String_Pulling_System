%% GetTimeSegmentsUtc()
% Retrieves all segment times in UTC time

% Inputs
%   szExpPath               the Experiment folder
%   channelId               channel ID (see GetExperimentInfo.m)

% Outputs
%   segStartTimesUtc        UTC segment start times
%   segEndTimesUtc          UTC segment end times 

function [segStartTimesUtc, segEndTimesUtc] = GetTimeSegmentsUtc(szExpPath, channelId)
%% Initialize arrays
segStartTimesUtc = NET.createArray('System.DateTime', 0);
segEndTimesUtc = NET.createArray('System.DateTime', 0);

%% Load WaveformFile Assembly if not already loaded
if isempty(which('Ponemah.WaveformFile.WaveformDatasetReader'))
    [mFilePath,~,~] = fileparts(mfilename('fullpath'));
    NET.addAssembly(strcat(mFilePath, '\Ponemah.WaveformFile.dll'));
end

%% Retrieve available channels
reader = Ponemah.WaveformFile.WaveformDatasetReader();
OpenDataset(reader, szExpPath);
ScanForAvailableData(reader);
channelIds = GetChannelIds(reader);
channelIdArray = NET.invokeGenericMethod('System.Linq.Enumerable', 'ToArray', {'System.Int64'}, channelIds);


%% Verify the requested channelId is valid
channelIdFound = false;
for idx = 1:channelIdArray.Length
    if channelIdArray(idx) == channelId
        channelIdFound = true;
    end
end

%% Retrieve segments from the Waveform file
if channelIdFound == true
    % Get Time Segments
    timeSegments = GetChannelTimeSegments(reader, channelId);

    segStartTimesUtc = NET.createArray('System.DateTime', timeSegments.Count);
    segEndTimesUtc = NET.createArray('System.DateTime', timeSegments.Count);
    
    for idx = 0:timeSegments.Count-1
        seg = Item(timeSegments, idx);
        segStartTimesUtc(idx+1) = seg.Start;
        segEndTimesUtc(idx+1) = seg.End;
    end
end
