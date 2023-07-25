%% Plot 1000 points from a specific timepoint

%% User Inputs
szExpPath = 'C:\Ponemah_Data\Exp_1Subj_ECG_BP_Scheduled';
channelId=2;
numSamplesRequested = 1000;
% Define the start time as a .NET DateTime value
startTimeLocal = System.DateTime(1999, 5, 28, 13, 00, 15, 0);  % (Y, M, D, h, m, s, ms)

% Setup to request Data
[reader, timezone, segStartTimesUtc, segEndTimesUtc, sampleRate, sampleBuffer] = GetPnmWaveformData_Setup(szExpPath, channelId, numSamplesRequested);

% Convert requested time to UTC
startTimeUtc = System.TimeZoneInfo.ConvertTimeToUtc(startTimeLocal, timezone);
% Request Data
[actualStartTimeUtc, samplesReturned ] = GetPnmWaveformDataUtc(reader, channelId, startTimeUtc, numSamplesRequested, sampleBuffer, sampleRate, segStartTimesUtc, segEndTimesUtc);

% Plot Data
plot(sampleBuffer);


