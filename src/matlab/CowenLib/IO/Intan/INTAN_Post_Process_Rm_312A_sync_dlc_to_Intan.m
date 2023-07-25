function INTAN_Post_Process_Rm_312A_sync_dlc_to_Intan(intan_data_dir, varargin)
% Assumes that deeplab cut has been run and that the INTAN data has been
% post-processed. The deep lab cut directory (DLC) should be in the directory 
% ABOVE the INTAN data directory.
%  e.g.: 'Z:\Data\String_Pull_312a\RECORDING SESSIONS\Rat 333\3\DLC'
%
% INPUT:
%  intan_data_dir - the root directory where the INTAN data was stored
%     for example: 'Z:\Data\String_Pull_312a\RECORDING_SESSIONS\Rat_333\3\Rec_210818_101300'
%  event_name - the name of the sub-structure in the event file that
%     corresponds for example 'top_camera_frame_ID' from teh EVT structure.
%  dlc_csv_file_path - full path to the dlc file corresponding to the
%     event_name
%
% optional: PRM - a strcture that specifices the specific cameras that will
% be processed (and the EVT variables).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PRM.camera_list = {'Top_Cam' 'Front_Cam'}; % names should correspond to the folder names in /DLC that correspond to each camera.
PRM.EVT_file_sync_variable = {'top_camera_frame_uS' 'front_camera_frame_uS'};
% PRM.camera_list = {'Front_Cam'};
% PRM.EVT_file_sync_variable = {'front_camera_frame_uS'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Extract_varargin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

root_dir = fileparts(intan_data_dir);

% load the events...
if ~exist(fullfile(intan_data_dir,'EVT.mat'),'file')
    fullfile(intan_data_dir,'EVT.mat')
    error('no EVT.mat file')
end
load(fullfile(intan_data_dir,'EVT.mat'),'EVT')
%% Sync each camera in PRM.camera_list
POS = [];
POS_info = [];
for iC = 1:length(PRM.camera_list)
    cam = PRM.camera_list{iC};
    cam_evt_vbl = PRM.EVT_file_sync_variable{iC};
    dlc_csv_file_path = fullfile(root_dir,'DLC',cam);
    d = dir(fullfile(dlc_csv_file_path,'*.csv'));
    if length(d) < 1
        disp(['No .csv file from DeepLabCut found for ' cam ])
    elseif length(d) > 1
        d
        error('Multiple .csv files found')
    end
    dlc_csv_file_path = fullfile(dlc_csv_file_path,d(1).name);
    
    if exist(dlc_csv_file_path,'file')
        disp(['Found ' cam])
        % The following also creates the relevant .mat files in the .csv
        % directory.
        [POS{iC}, POS_info{iC}] = INTAN_Sync_DeepLabCut_csv_to_Intan(dlc_csv_file_path, EVT.(cam_evt_vbl)(:,1), cam);
    end
    % Now that this is finished, compare the POS data from the cameras to
    % the IMU data and string pulling events from the INTAN system as a sanity check. They should
    % line up.
    INTAN_Compare_Camera_Tracking_to_Intan_Movement_Data(intan_data_dir, POS_info{iC}.POS_file_path)
end
