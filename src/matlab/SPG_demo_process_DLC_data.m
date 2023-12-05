%% Demo to illustrate how front-camera data and its output from deeplabcut can be...
% 1) synchronized frames with neural recording data (to yield Intan_uS which are
% timestamps in microseconds aligned to the Intan recording time.
% 2) How deep lab cut data can be furhter cleaned up, converted to polar
% coordinates and then segmented into different
% reach\advance\grasp\pull\push segments.
%
% The end result of running this should be some pretty plots of segmented
% reach/grasp data.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dlc_csv_file = '1fDLC_resnet101_FRONTCamTrainingAug20shuffle1_1030000.csv'; % Assumes the dlc csv file is in this directory. Change if you change the directory
event_file = 'EVT.mat'; % A matlab file that has INTAN event times for when each frame from the front cam was acquired.
% Load event times
load(event_file,'EVT')
% Convert the DeepLabCut csv file to a more manageable matlab table and sync with the INTAN recording system
[POS, POS_info] = INTAN_Sync_DeepLabCut_csv_to_Intan(dlc_csv_file, EVT.front_camera_frame_uS(:,1), 'Front_Camera');

% Add more informaiton to the DeepLabCut data such as phase of the pull. Clean up bad data as well.
[SEG] = SPG_Load_and_Clean_DLC_Front_Camera_Tracking(POS);

% Generate some plots now that the data has been processed.
SPG_plot_segmented_paw_position(SEG);

SPG_plot_polar_plot_of_paw_position(SEG);


