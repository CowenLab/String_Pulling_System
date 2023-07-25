function NPXL_RunKilosort_2_SS(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Runs Kilosort 2.5 on ap.bin files (after CatGT and denoising the data)
% %However this function will run on any ap.bin file
% 
% Runs using https://djoshea.github.io/neuropixel-utils/ functions/dataset
% Needs to be added to dir
%eg:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%INPUT PARAMETERS
PRM_TEMP_FOLDER_LOCATION='D:\KS_Output';
PRM_chanMapPath='C:\Users\CowenLab\Documents\GitHub\Kilosort-2.0\configFiles';
PRM_chanMapFile='neuropixPhase3B2_kilosortChanMap.mat'; %Code below assumes .mat file
PRM_BIN_FNAME='';

Extract_varargin;
%Directories to ADD
PRM_NEUROPIXEL_UTILS_DIR = fullfile(Git_dir,'neuropixel-utils'); % if this works for you, go for it
% Otherwise, do this if you do not have the folder.
% PRM_NEUROPIXEL_UTILS_DIR = 'C:\Users\cowen\Documents\GitHub\neuropixel-utils';
addpath(genpath(PRM_NEUROPIXEL_UTILS_DIR));

%Same for Kilosort 2.0
PRM_KILOSORT25_DIR = fullfile(Git_dir,'Kilosort-2.0'); % 
% PRM_NEUROPIXEL_UTILS_DIR = 'C:\Users\CowenLab\Documents\GitHub\Kilosort-2.5';
addpath(genpath(PRM_KILOSORT25_DIR));

%Create Channel Map Class from Neuropixels util
CLASS_chanMap=Neuropixel.ChannelMap(fullfile(PRM_chanMapPath,PRM_chanMapFile));

%Create ImecDataset
CLASS_imec=Neuropixel.ImecDataset(PRM_BIN_FNAME,'channelMap', CLASS_chanMap);

%Run Kilosort 
Neuropixel.runKilosort2_modified(CLASS_imec, 'saveDir',PRM_TEMP_FOLDER_LOCATION,...
    'workingDir',PRM_TEMP_FOLDER_LOCATION);