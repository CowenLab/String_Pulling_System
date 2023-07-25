%% Request all data

%% User Inputs
szExpPath = 'C:\Ponemah_Data\Exp_1Subj_ECG_BP_Scheduled';
channelId=2;
numSamplesRequested = 100000;

% Setup to request Data
[reader, timezone, segStartTimesUtc, segEndTimesUtc, sampleRate, sampleBuffer] = GetPnmWaveformData_Setup(szExpPath, channelId, numSamplesRequested);
for segIdx=1:segStartTimesUtc.Length
    currentUtc = segStartTimesUtc(segIdx);
    segEndUtc = segEndTimesUtc(segIdx);
    while currentUtc < segEndUtc
        [actualStartTimeUtc, samplesReturned ] = GetPnmWaveformDataUtc(reader, channelId, currentUtc, numSamplesRequested, sampleBuffer, sampleRate, segStartTimesUtc, segEndTimesUtc);

        % Process Retrieved Data
        % .....
        % .....
        % .....
        currentUtc = actualStartTimeUtc.AddMilliseconds(1000*samplesReturned/double(sampleRate));
    end
end
