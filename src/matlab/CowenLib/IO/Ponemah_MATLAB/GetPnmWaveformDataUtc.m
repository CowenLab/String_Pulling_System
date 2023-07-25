%% GetPnmWaveformDataUtc()
% Retrieves sample data from an Experiment waveform file 
% Prerequisites: GetPnmWaveformData_Setup() must be called prior to calling this function

% Inputs
%   reader                  WaveformDatasetReader object
%   channelId               channel ID (see GetExperimentInfo.m)
%   startTimeUtc            UTC time of first requested sample
%   numSamplesRequested     num samples requested
%   sampleBuffer            buffer in which samples are stored
%   sampleRate              channel sample rate
%   segStartTimesUtc        channel UTC segment start times
%   segEndTimesUtc          channel UTC segment end times

% Outputs
%   actualStartTimeUtc      UTC time of the first sample returned in sampleBuffer
%   samplesReturned         number of samples returned in sampleBuffer

function [actualStartTimeUtc, samplesReturned ] = GetPnmWaveformDataUtc(reader, channelId, startTimeUtc, numSamplesRequested, sampleBuffer, sampleRate, segStartTimesUtc, segEndTimesUtc)

%% Identify the data segment that contains the requested data
for idx = 1:segStartTimesUtc.Length
    if startTimeUtc < segStartTimesUtc(idx)
        startTimeUtc = segStartTimesUtc(idx);
        endTimeUtc = segEndTimesUtc(idx);
        break
    end
    if startTimeUtc >= segStartTimesUtc(idx) && startTimeUtc <= segEndTimesUtc(idx)
        endTimeUtc = segEndTimesUtc(idx);
        break
    end
end

%% Report an error if no samples are at or beyond the requested time
if segStartTimesUtc.Length < 1 || startTimeUtc > segEndTimesUtc(segEndTimesUtc.Length)
    error('no samples available');
end

%% Start from the first sample at or after the requested time
actualStartTimeUtc = startTimeUtc;

%% Adjust the number of samples based on available contiguous data
range = endTimeUtc - startTimeUtc;
availableSamples = range.Ticks * sampleRate/10000000;

if availableSamples < numSamplesRequested
    numSamplesRequested = double(availableSamples);
end

%% Retrieve data
samplesReturned = GetSamples(reader, channelId, startTimeUtc, sampleBuffer, numSamplesRequested);

