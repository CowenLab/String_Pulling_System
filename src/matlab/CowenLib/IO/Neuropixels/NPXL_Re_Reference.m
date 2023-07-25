% Assumes https://github.com/djoshea/neuropixel-utils is in your GitHub
clearvars
addpath(fullfile(Git_dir,'neuropixel-utils'))
% addpath(genpath('C:\Neuropixels\Kilosort-2.0'))
fclose all;
% Demo 
% cleanedPath = 'C:/Temp';
bin_fname = 'mouse_bank0_run2_g0_t0.imec0.ap.bin';
channelMapFile = 'C:\Neuropixels\Kilosort-2.0\configFiles\neuropixPhase3B2_kilosortChanMap.mat';
data_dir = 'C:\Data\mouse_bank0_run2_g0\mouse_bank0_run2_g0_imec0\';
fname = fullfile(data_dir, bin_fname);

% data_dir = 'G:\Data\Transcranial_Optogenetics\Mouse5\1\mouse_bank0_run3_g0\mouse_bank0_run3_g0_imec0\';
% fname = fullfile(data_dir, 'mouse_bank0_run3_g0_t0.imec0.ap.bin');

cleanedPath = fullfile(data_dir,'Cleaned'); % put it in the data dir.
% fname = 'G:\Data\Transcranial_Optogenetics\Mouse5\1\mouse_bank0_run3_g0\mouse_bank0_run3_g0_imec0\mouse_bank0_run3_g0_t0.imec0.ap.bin';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist(cleanedPath,'dir')
    mkdir(cleanedPath)
else
    delete(fullfile(cleanedPath,'*.bin'))
    delete(fullfile(cleanedPath,'*.meta'))
end
imec = Neuropixel.ImecDataset(fname, 'channelMap',channelMapFile);
% rmsBadChannels = imec.markBadChannelsByRMS('rmsRange', [3 100]);
% imec.setSyncBitNames([1 2 3], {'trialInfo', 'trialStart', 'stim'});
% imec.writeModifiedAPMeta(); % not sure if this is necessary.
% extraMeta = struct();
% extraMeta.commonAverageReferenced = true;
%  fnList = {@Neuropixel.DataProcessFn.commonAverageReference};
% imec = imec.saveTransformedDataset(cleanedPath, 'transformAP', fnList, 'extraMeta', extraMeta);
 fnList = {@Neuropixel.DataProcessFn.commonRegressionResiduals};
 fnList = {@Neuropixel.DataProcessFn.commonRegressionResidualsOpt};
%imec = imec.saveTransformedDataset(cleanedPath, 'transformAP', fnList, 'extraMeta', extraMeta);
% Don't save with the new meta. Use the old one.
tic
imec2 = imec.saveTransformedDataset(cleanedPath, 'transformAP', fnList,'gpuArray',false);  %'gpuArray',true
fprintf('That took %1.2f hours. Data in %s\n',toc/3600, imec2.fileAP);

out_file = fullfile(cleanedPath,imec2.fileAP);
% imec2.writeModifiedAPMeta();
% imec2.chunkSize
% get the filename with imec2.fileAP

% Sym link the cleaned dataset into a separate directory for Kilosort2
% ksPath = '/data/kilosort/neuropixel_01.imec.ap.bin';
% >> imec = imec.symLinkAPIntoDirectory(ksPath);

% Inspect the raw IMEC traces
% imec.inspectAP_timeWindow([200 201]); % 200-201 seconds into the recording
figure
imec.inspectAP_timeWindow([100 101],'channels',15:24); % 200-201 seconds into the recording
% fname_new = 'C:\Temp\Temp.imec.ap.bin';
% imec2 = Neuropixel.ImecDataset(fname_new, 'channelMap',channelMapFile);
% figure
figure
imec2.inspectAP_timeWindow([100 101],'channels',15:24); % 200-201 seconds into the recording


ch_index = 10:14;
sample_index = 100000:120000;
mmap = imec.memmapAP_full();
value = mmap.Data.x(ch_index, sample_index); % access a specific sample
imec2 = Neuropixel.ImecDataset(out_file, 'channelMap',channelMapFile);
% 
mmap2 = imec2.memmapAP_full();
value2 = mmap2.Data.x(ch_index, sample_index); % access a specific sample
figure
plot(rms(value,2))
hold on
plot(rms(value2,2))

ca
plot(value(4,:)')
hold on
plot(value2(4,:)')
%
secStart = 10;
secStop = 20;
timeWindow = [secStart, secStop]; % in seconds
[data_partial, sampleIdx] = imec.readAP_timeWindow(timeWindow);

% Run kilosort...
Neuropixel.runKilosort2(imec2);