% INTAN_Post_Process_Rm_312A_test
%% A test script to make sure that the post-processing is actually working.
intan_data_dir = 'Z:\RECORDING_SESSIONS\Rat_339\2\Rec_211026_150707';


PRM.camera_list = {'Front_Cam'};
PRM.EVT_file_sync_variable = {'front_camera_frame_uS'};

PRM.camera_list = {'Top_Cam'};
PRM.EVT_file_sync_variable = {'top_camera_frame_uS'};


PRM.camera_list = {'Top_Cam' 'Front_Cam'};
PRM.EVT_file_sync_variable = {'top_camera_frame_uS' 'front_camera_frame_uS'};

%% Run the code....
INTAN_Post_Process_Rm_312A_sync_dlc_to_Intan(intan_data_dir, 'PRM', PRM)

%%%%%%%%%%%%%%%%%%%%%%%%%%
POS_file_path = 'Z:\RECORDING_SESSIONS\Rat_339\2\DLC\Front_Cam_Pos.mat';
POS_file_path = 'Z:\RECORDING_SESSIONS\Rat_339\2\DLC\Top_Cam\Top_Cam_Pos.mat';
INTAN_Compare_Camera_Tracking_to_Intan_Movement_Data(intan_data_dir, POS_file_path)