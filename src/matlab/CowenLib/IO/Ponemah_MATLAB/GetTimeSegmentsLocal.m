%% GetTimeSegmentsLocal()
% Retrieves all segment times in Local(Experiment) time

% Inputs
%   szExpPath               the Experiment folder
%   channelId               channel ID (see GetExperimentInfo.m)

% Outputs
%   segStartTimesLocal      Local segment start times (acq timezone)
%   segEndTimesLocal        Local segment end times (acq timezone)

function [segStartTimesLocal, segEndTimesLocal] = GetTimeSegmentsLocal(szExpPath, channelId)

%% Initialize arrays
segStartTimesLocal = NET.createArray('System.DateTime', 0);
segEndTimesLocal = NET.createArray('System.DateTime', 0);

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

%% Retrieve the segments in UTC
[segStartTimesUtc, segEndTimesUtc] = GetTimeSegmentsUtc(szExpPath, channelId);

%% Convert UTC to Local
if segStartTimesUtc.Length > 0
    segStartTimesLocal = NET.createArray('System.DateTime', segStartTimesUtc.Length);
    segEndTimesLocal = NET.createArray('System.DateTime', segStartTimesUtc.Length);
    
    for idx = 1:segStartTimesUtc.Length
        % adjust start time from utc to experiment time zone
        segStartTimesLocal(idx) = System.TimeZoneInfo.ConvertTimeFromUtc(segStartTimesUtc(idx), timezone);
        % adjust end time from utc to experiment time zone
        segEndTimesLocal(idx) = System.TimeZoneInfo.ConvertTimeFromUtc(segEndTimesUtc(idx), timezone);
    end
end
