%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NPXL_Post_Process_Run
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The high-level code for running all of the post processing.
% Feel free to copy this and make a version for your own data
% post-processing. This code runs CatGT, extracts events, and
% filters/proceses .ap and .lf files for spike sorting.
%
% Expects:
% An event_codes.csv file in the top directory. It contains the event
% channel, variable name, and notes.
% C:\CatGT-win
% C:\TPrime-win
% Assumes CowenLib
% Assumes in your GitHub folder: https://github.com/djoshea/neuropixel-utils
%

% You must run kilosort manually throught the GUI.
% You must run Tprime after spike sorting to ensure aligned spikes and
% event times.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Cowen 2022
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars; close all; fclose all;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Change variables here for your analysis.

%%DataDirs
PRM_RAT_ROOT='C:\SGL_DATA\Acute_DANA\Rat445';
PRM_RAT_SUBDIRS={'51923_DANA_700uM_WE_6500uM_bank0_g0'};
PRM_BAD_CHANNEL0_LIST = [12 36 84 103 134 160 183 191 205 206 240 248 226 329 340 352]; % This is ZERO based as you would see in SpikeGLX so be sure the first channel is zero.
PRM_TEMP_FOLDER_BASE = 'D:\DANA_KS_output'; % This needs to be a SSD.

%Functions to run
PRM_CREATE_TCAT_FILE = true; % make false if you already created this file on a previous run to save some time.
PRM_CREATE_LF_FILE=false; %make false if you don't want to run the LF files. Saves time
PRM_COPY_FILES=true; %If you want a copy of the tcat files copied from the Base dir to denoising/kilosort dir
PRM_CREATE_CHANNELMAP=true; %Will generate a new channel map if you are using a custom config
PRM_RUN_DENOISE=true;
PRM_RUN_KILOSORT=false; %DONNOT RUN

%Note if you run Channel Map make sure the meta file is in the same
%location where data was originally collected!!
%Otherwise uncomment the following two lines and add the parameters to the run command below

%PRM_chanMapPath='';
%PRM_chanMapFile'';

%%%%%%%%%%CatGT Parameters
%AP FILES

%LF FILES

%ANALOG FILES
PRM_EVENT_CHANNELS=[1:7]; %Which analog channels to extract
PRM_XA_Duration = [0]; %Time of pulses in ms - creates separate files. Good to keep 0 as a default
PRM_INAROW=3;

%Default Parameters for extracting 
% PRM_EVENT_CHANNELS = [1:7];% by default, get everything to avoid mistakes.
% PRM_XA_THR1=3.0;%Threshold for detecting xa (in V)
% PRM_XA_THR2=2.0;%Secondary threshold for detetcting xa (in V) -keep lower than THR1 for square pulses
% PRM_XA_Duration=[0.0];%Default timestamp detects all edges (in ms)
% PRM_XIA_THR1=-3.0;%inverse pulse Threshold for detecting xa (in V) inverse pulse
% PRM_XIA_THR2=-2.0;% inverse pulseSecondary threshold for detetcting xa (in V) -keep lower than THR1 for square pulses
% PRM_INAROW=3; %Min No. of continuous samples to detect for analog pulse

%Note if you uncomment any of the above parameters to change from default,
%you will need to declare the variable in the command below (varargin) and
%in the NPXL_Post_Process_SS file. 

PRM_CatGT_dir = 'C:\CatGT-win';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run it.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii=1:length(PRM_RAT_SUBDIRS) %Specify which subfolders here
    PRM_ROOT_DATA_DIR=fullfile(PRM_RAT_ROOT,PRM_RAT_SUBDIRS{ii});
    PRM_TEMP_FOLDER_LOCATION=fullfile(PRM_TEMP_FOLDER_BASE,PRM_RAT_SUBDIRS{ii});
    
    %Run the PostProcess 
    NPXL_Post_Process_SS('PRM_ROOT_DATA_DIR',PRM_ROOT_DATA_DIR,...
        'PRM_BAD_CHANNEL0_LIST',PRM_BAD_CHANNEL0_LIST,...
        'PRM_TEMP_FOLDER_LOCATION',PRM_TEMP_FOLDER_LOCATION,...
        'PRM_CREATE_TCAT_FILE',PRM_CREATE_TCAT_FILE,...
        'PRM_CREATE_LF_FILE',PRM_CREATE_LF_FILE,...
        'PRM_COPY_FILES',PRM_COPY_FILES,...
        'PRM_CREATE_CHANNELMAP',PRM_CREATE_CHANNELMAP,...
        'PRM_RUN_DENOISE',PRM_RUN_DENOISE,...
        'PRM_RUN_KILOSORT',PRM_RUN_KILOSORT,...
        'PRM_EVENT_CHANNELS',PRM_EVENT_CHANNELS,...
        'PRM_XA_Duration',PRM_XA_Duration,...
        'PRM_INAROW',PRM_INAROW);
end

        