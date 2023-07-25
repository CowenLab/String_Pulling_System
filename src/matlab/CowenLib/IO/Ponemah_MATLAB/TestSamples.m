% Retrieves sample data from Experiments and compares samples with expected
% results

function TestSamples()

    global PERMITTED_PERC_ERROR;
    global MIN_SIGNAL_VALUE;
    PERMITTED_PERC_ERROR = 1.3;
    MIN_SIGNAL_VALUE = 0.05;

    [mFilePath,~,~] = fileparts(mfilename('fullpath'));

    %% Exp_3Subj_ECG_BP_Continuous
    szExpPath = [mFilePath, '\TestData\Exp_3Subj_ECG_BP_Continuous'];
    CheckSamples(szExpPath, 2, [szExpPath, '\Channel2_1.ascii']);
    CheckSamples(szExpPath, 3, [szExpPath, '\Channel3_1.ascii']);
    CheckSamples(szExpPath, 6, [szExpPath, '\Channel6_1.ascii']);
    CheckSamples(szExpPath, 7, [szExpPath, '\Channel7_1.ascii']);
    CheckSamples(szExpPath, 10, [szExpPath, '\Channel10_1.ascii']);
    CheckSamples(szExpPath, 11, [szExpPath, '\Channel11_1.ascii']);

    %% Exp_1Subj_EEG_EMG_SignalStrength_Continuous
    szExpPath = [mFilePath, '\TestData\Exp_1Subj_EEG_EMG_SignalStrength_Continuous'];
    CheckSamples(szExpPath, 2, [szExpPath, '\Channel2_1.ascii']);
    CheckSamples(szExpPath, 3, [szExpPath, '\Channel3_1.ascii']);



    %% Exp_1Subj_ECG_BP_Scheduled
    szExpPath = [mFilePath, '\TestData\Exp_1Subj_ECG_BP_Scheduled'];
    CheckSamples(szExpPath, 2, [szExpPath, '\Channel2_1.ascii']);
    CheckSamples(szExpPath, 3, [szExpPath, '\Channel3_1.ascii']);
    
    disp('All tests passed')
end

    function CheckSamples(szExpPath, channelId, inputFile)
        fprintf('\n%s\n', inputFile);
        [knownSamples, sampleStartTimeLocal] = GetKnownSamples(inputFile);
        [maxPercError, errSample1, errSample2] = ReadDefinedTime(szExpPath, channelId, knownSamples, sampleStartTimeLocal);
        %fprintf('ReadDefinedTime: max Error=%f, sample1=%f, sample2=%f \n', maxPercError, errSample1, errSample2);

        [maxPercError, errSample1, errSample2] = ReadAllData(szExpPath, channelId, knownSamples, sampleStartTimeLocal);
        %fprintf('ReadAllData: max Error=%f, sample1=%f, sample2=%f \n', maxPercError, errSample1, errSample2);
        disp('Passed');
    end
        
    function [knownSamples, sampleStartTimeLocal] = GetKnownSamples(inputFile)
        fileId = fopen(inputFile, 'r');
        line = fgetl(fileId);

        knownSamples = [];
        while ischar(line)
            a = strsplit(line, ',');
            if 0 == size(knownSamples, 2)
                % not able to directly convert the string with milliseconds
                % to a datetime()
                sampleStartTimeLocal = datetime(datenum(datevec(a(1), 'mm/dd/yyyy HH:MM:SS.FFF AM')), 'ConvertFrom', 'datenum');
            end
            knownSamples(end+1) = str2double(a(2));
            line = fgetl(fileId);
        end
        fclose(fileId);
    end


    function [maxPercError, errSample1, errSample2] = ReadDefinedTime(szExpPath, channelId, knownSamples, startTimeLocal)
        global PERMITTED_PERC_ERROR;
        global MIN_SIGNAL_VALUE;

        maxPercError = 0;
        numSamplesRequested = size(knownSamples, 2);
        % Setup to request Data
        [reader, timezone, segStartTimesUtc, segEndTimesUtc, sampleRate, sampleBuffer] = GetPnmWaveformData_Setup(szExpPath, channelId, numSamplesRequested);
        % Define the start time as a .NET DateTime value
        t = startTimeLocal;
        % convert from datetime to System.DateTime
        startTimeLocal = System.DateTime(t.Year, t.Month, t.Day, t.Hour, t.Minute, floor(t.Second), (t.Second - floor(t.Second))*1000);  %(Y,M,D,H,M,S,mS)
        % Convert to UTC
        startTimeUtc = System.TimeZoneInfo.ConvertTimeToUtc(startTimeLocal, timezone);
        % Request Data
        [actualStartTimeUtc, samplesReturned ] = GetPnmWaveformDataUtc(reader, channelId, startTimeUtc, numSamplesRequested, sampleBuffer, sampleRate, segStartTimesUtc, segEndTimesUtc);

        for idx=1:numSamplesRequested
            errPercentage = abs((knownSamples(idx) - sampleBuffer(idx))/sampleBuffer(idx)) * 100;
            if maxPercError < errPercentage && knownSamples(idx)> MIN_SIGNAL_VALUE
                maxPercError = errPercentage;
                errSample1 = knownSamples(idx);
                errSample2 = sampleBuffer(idx);
            end
            if errPercentage > PERMITTED_PERC_ERROR && (knownSamples(idx)> MIN_SIGNAL_VALUE || sampleBuffer(idx)> MIN_SIGNAL_VALUE)
                error('Sample %d does not match (%f, %f, %f)', idx, knownSamples(idx), sampleBuffer(idx), errPercentage);
            end
        end
    end


    function [maxPercError, errSample1, errSample2] = ReadAllData(szExpPath, channelId, knownSamples, startTimeLocal)
        global PERMITTED_PERC_ERROR;
        global MIN_SIGNAL_VALUE;

        numSamplesRequested = 100000;
        numKnownSamples = size(knownSamples, 2);
        maxPercError = 0;
        
        % Setup to request Data
        [reader, timezone, segStartTimesUtc, segEndTimesUtc, sampleRate, sampleBuffer] = GetPnmWaveformData_Setup(szExpPath, channelId, numSamplesRequested);
        % Define the start time as a .NET DateTime value
        t = startTimeLocal;
        % convert from datetime to System.DateTime
        startTimeLocal = System.DateTime(t.Year, t.Month, t.Day, t.Hour, t.Minute, floor(t.Second), (t.Second - floor(t.Second))*1000);  %(Y,M,D,H,M,S,mS)
        % Convert to UTC
        startTimeUtc = System.TimeZoneInfo.ConvertTimeToUtc(startTimeLocal, timezone);
        
        bFirstSampleFound = false;
        for segIdx=1:segStartTimesUtc.Length
            currentUtc = segStartTimesUtc(segIdx);
            segEndUtc = segEndTimesUtc(segIdx);
            while currentUtc < segEndUtc
                [actualStartTimeUtc, samplesReturned ] = GetPnmWaveformDataUtc(reader, channelId, currentUtc, numSamplesRequested, sampleBuffer, sampleRate, segStartTimesUtc, segEndTimesUtc);
                endUtc = actualStartTimeUtc.AddMilliseconds(1000*samplesReturned/double(sampleRate));
                % Look for known samples
                if not(bFirstSampleFound)
                    if startTimeUtc >= actualStartTimeUtc && startTimeUtc < endUtc
                        offsetTimespan = (startTimeUtc - actualStartTimeUtc);
                        startOffset = offsetTimespan.TotalSeconds * double(sampleRate);
                        bFirstSampleFound = true;
                        
                        for idx=1:numKnownSamples
                            if startOffset+idx > numSamplesRequested 
                                disp('************** all samples not checked');
                                break
                            end
                            errPercentage = abs((knownSamples(idx) - sampleBuffer(int32(startOffset + idx)))/sampleBuffer(int32(startOffset + idx))) * 100;
                            if maxPercError < errPercentage && knownSamples(idx)> MIN_SIGNAL_VALUE
                                maxPercError = errPercentage;
                                errSample1 = knownSamples(idx);
                                errSample2 = sampleBuffer(int32(startOffset + idx));
                            end
                            if errPercentage > PERMITTED_PERC_ERROR (knownSamples(idx)> MIN_SIGNAL_VALUE || sampleBuffer(int32(startOffset + idx))> MIN_SIGNAL_VALUE)
                                error('Sample %d does not match (%f, %f, %f)', idx, knownSamples(idx), sampleBuffer(int32(startOffset + idx)), errPercentage);
                            end
                        end
                    end
                end
                
                currentUtc = endUtc;
            end
        end
    end
