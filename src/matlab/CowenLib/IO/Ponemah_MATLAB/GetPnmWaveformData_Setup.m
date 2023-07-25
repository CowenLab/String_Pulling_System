%% GetPnmWaveformData_Setup()
% Setup function called prior to making one or more calls to GetPnmWareformDataUtc()

% Inputs
%   szExpPath               the Experiment folder
%   channelId               channel ID (see GetExperimentInfo.m)
%   numSamplesRequested     num samples

% Outputs
%   reader                  WaveformDatasetReader object
%   timezone                Experiment timezone
%   segStartTimesUtc        segment start times in UTC
%   segEndTimesUtc          segment end times in UTC
%   sampleRate              samples/sec 
%   sampleBuffer            buffer allocated to retrieve samples

function [reader, timezone, segStartTimesUtc, segEndTimesUtc, sampleRate, sampleBuffer] = GetPnmWaveformData_Setup(szExpPath, channelId, numSamplesRequested)

%% Load WaveformFile Assembly if not already loaded
if isempty(which('Ponemah.WaveformFile.WaveformDatasetReader'))
    [mFilePath,~,~] = fileparts(mfilename('fullpath'));
    NET.addAssembly(strcat(mFilePath, '\Ponemah.WaveformFile.dll'));
end

%% Load Ponemah6xExtractor Assembly if not already loaded
if isempty(which('Ponemah6xExtractor.Ponemah6XExtractor'))
    [mFilePath,~,~] = fileparts(mfilename('fullpath'));
    NET.addAssembly(strcat(mFilePath, '\Ponemah6xExtractor.dll'));
end

%% Get Experiment database
[~,szExpName,~] = fileparts(szExpPath);
szExpDatabase = [szExpPath, '\', szExpName, '.PnmExp'];

%% Get Timezone information
timezone = Ponemah6xExtractor.Ponemah6XExtractor.GetTimeZone(szExpDatabase);

%% Retrieve available channels
reader = Ponemah.WaveformFile.WaveformDatasetReader();
OpenDataset(reader, szExpPath);
ScanForAvailableData(reader);
channelIds = GetChannelIds(reader);
channelIdArray = NET.invokeGenericMethod('System.Linq.Enumerable', 'ToArray', {'System.Int64'}, channelIds);

%% Verify requested channelId is valid
channelIdFound = false;
for idx = 1:channelIdArray.Length
    if channelIdArray(idx) == channelId
        channelIdFound = true;
    end
end
if channelIdFound == false
    error('Invalid channel');
end


%% Get Segments start and end times
[segStartTimesUtc, segEndTimesUtc] = GetTimeSegmentsUtc(szExpPath, channelId);
ticksPerSample = GetTicksPerSample(reader, channelId, segStartTimesUtc(1));
sampleRate = 10000000/ticksPerSample.Ticks;         % This assumes that the sample rate remains constant throughout the range of data 

%% Allocate a float buffer for internal use
sampleBuffer = NET.createArray('System.Single', numSamplesRequested);

