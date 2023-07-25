% Compares the output from GetExperimentInfo() with expected results

%% Obtain the local folder
[mFilePath,~,~] = fileparts(mfilename('fullpath'));

%% Exp_3Subj_ECG_BP_Continuous
szExpPath = [mFilePath, '\TestData\Exp_3Subj_ECG_BP_Continuous'];
outputFile = [mFilePath, '\TestData\TestOutput\ExpInfo1.txt'];
fileId = fopen(outputFile, 'w');
GetExperimentInfo(szExpPath, fileId);
fclose(fileId);
testOutput = fileread(outputFile);

expectedResult = fileread([szExpPath, '\ExpInfo.txt']);
if 0==strcmp(testOutput, expectedResult)
    error('compare failed');
end


%% Exp_1Subj_EEG_EMG_SignalStrength_Continuous
szExpPath = [mFilePath, '\TestData\Exp_1Subj_EEG_EMG_SignalStrength_Continuous'];
outputFile = [mFilePath, '\TestData\TestOutput\ExpInfo2.txt'];
fileId = fopen(outputFile, 'w');
GetExperimentInfo(szExpPath, fileId);
fclose(fileId);
testOutput = fileread(outputFile);

expectedResult = fileread([szExpPath, '\ExpInfo.txt']);
if 0==strcmp(testOutput, expectedResult)
    error('compare failed');
end

%% Exp_1Subj_ECG_BP_Scheduled
szExpPath = [mFilePath, '\TestData\Exp_1Subj_ECG_BP_Scheduled'];
outputFile = [mFilePath, '\TestData\TestOutput\ExpInfo3.txt'];
fileId = fopen(outputFile, 'w');
GetExperimentInfo(szExpPath, fileId);
fclose(fileId);
testOutput = fileread(outputFile);

expectedResult = fileread([szExpPath, '\ExpInfo.txt']);
if 0==strcmp(testOutput, expectedResult)
    error('compare failed');
end

disp('Test passed')