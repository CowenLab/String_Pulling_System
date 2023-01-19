function GP = LK_Globals()
% function GP = LK_Globals()
% Determine some global values that stay constant through all analyses.
%
%%%%%%%%%%
% Cowen 2020
%%%%%%%%%%
% Important file names...
GP = [];

GP.fnames.paw_file = 'Filtered_Time_Stamped_Coordinates.mat';
GP.fnames.imu_file = 'Inertial_data.mat';
GP.fnames.spike_file = 'AllSpikes.mat';
GP.fnames.event_file = 'EVT.mat';
GP.fnames.pos_file = 'POS.mat';
GP.fnames.meta_file = 'Meta_data.mat';
GP.fnames.session_info_file = 'SessionInfo.xlsx';
GP.fnames.string_pull_intervals_file = 'good_string_pull_intervals_uSec.mat';

GP.topdown_pixel_to_cm = nan; % need to determine this.
GP.front_pixel_to_cm = nan; % need to determine this.

GP.Colors.Control = [.1 .1 .1];
GP.Colors.Ketamine = [.8 .1 .1];
GP.Colors.LID = [.2 .8 .1];
GP.Colors.LeftPaw = [.7 .4 .2];
GP.Colors.RightPaw = [.2 .4 .7];
GP.Colors.Nose = [.4 .7 .2];

%%%%%%%%%%%%%%%%

