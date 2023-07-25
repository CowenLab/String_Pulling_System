%% Plot the first 1000 datapoints

%% User Inputs
szExpPath = 'C:\Ponemah_Data\Exp_1Subj_ECG_BP_Scheduled';
channelId=2;
numSamplesRequested = 1000;

% Setup to request Data
[reader, timezone, segStartTimesUtc, segEndTimesUtc, sampleRate, sampleBuffer] = GetPnmWaveformData_Setup(szExpPath, channelId, numSamplesRequested);
% Request Data
[actualStartTimeUtc, samplesReturned ] = GetPnmWaveformDataUtc(reader, channelId, segStartTimesUtc(1), numSamplesRequested, sampleBuffer, sampleRate, segStartTimesUtc, segEndTimesUtc);

% Plot Data
plot(sampleBuffer);


