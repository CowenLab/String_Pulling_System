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

% PRM_ROOT_DATA_DIR = 'G:\Data\Transcranial_Optogenetics\Mouse5\1\mouse_bank0_run3_g0'
% PRM_BAD_CHANNEL0_LIST = [1 41 163 191 233 266 279 285 292 355 372 376]; % This is ZERO based as you would see in SpikeGLX so be sure the first channel is zero.
PRM_ROOT_DATA_DIR = 'G:\Data\Transcranial_Optogenetics\Mouse5\1\mouse_bank0_run2_g0';
PRM_BAD_CHANNEL0_LIST = [1 41 137 163 191 194 233 256 261 266 279 280 285 372 376]; % This is ZERO based as you would see in SpikeGLX so be sure the first channel is zero.
PRM_TEMP_FOLDER_LOCATION = 'D:\Temp\SpikeSorting\Run2b'; % This needs to be a SSD.
% PRM_ROOT_DATA_DIR = 'G:\Data\Transcranial_Optogenetics\Mouse5\1\mouse_bank0_run1_g0';
% PRM_BAD_CHANNEL0_LIST = [1 36 41 191 233 256 261 266 279 280 285 372 376]; % This is ZERO based as you would see in SpikeGLX so be sure the first channel is zero.
% PRM_TEMP_FOLDER_LOCATION = 'D:\Temp\SpikeSorting\Run1'; % This needs to be a SSD.


PRM_CREATE_TCAT_FILE = true; % make false if you already created this file on a previous run to save some time.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run it.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NPXL_Post_Process('PRM_ROOT_DATA_DIR',PRM_ROOT_DATA_DIR,'PRM_BAD_CHANNEL0_LIST',...
    PRM_BAD_CHANNEL0_LIST,'PRM_TEMP_FOLDER_LOCATION',...
    PRM_TEMP_FOLDER_LOCATION,'PRM_CREATE_TCAT_FILE',PRM_CREATE_TCAT_FILE)

