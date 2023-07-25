function GP = SPG_Globals(user)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine global values that stay constant through all analyses.
%
%%%%%%%%%%
% Cowen 2023
%%%%%%%%%%
if nargin == 0
    user = 'Stephen';
end

GP = [];
GP.phase_codes = table({'grasp' 'pull' 'reach' 'release'}',[165 185;210 300;40 130;350 10],'VariableNames',{'phase_label','phase_range_deg'});
% Not really - I have better segmentation now I thinkl
GP.phase_codes2={'lift' 'advance' 'grasp' 'pull' 'push'}; % this is more akin to the Blackwell work.
GP.phase_codes3={'reach','witdraw' };

% phase codes that require more processing.
% GP.phase_codes_detailed = table({'lift' 'advance' 'grasp' 'push' 'pull' 'reach' 'withdraw'}',[],'VariableNames',{'phase_label','phase_range_deg'});

GP.cm_per_tic_of_rot_encoder = 40.64/113; % Gabe will double check this.
GP.top_cm_per_pixel = 0.16679;
% GP.front_cm_per_pixel = 5/180; % Gabe's estimate
GP.front_cm_per_pixel = 7.4/304; % Stephen's estimate. Done in the x dimension. y might be different.
GP.vertical_pixels = 880;
GP.horzontal_pixels = 600;
% Parameters for identifying a pulling bout.
GP.pull_bout_threshold_speed_rot_encoder = 5;
GP.pull_bout_threshold_speed_rot_encoder_low_thresh = GP.pull_bout_threshold_speed_rot_encoder*.2;

GP.pull_bout_minimum_duration_uS = 2e6;
GP.pull_bout_minimum_inter_interval_period_uS = 3e6;

% Colors for plots.
GP.Colors.Control = [.1 .1 .1];
GP.Colors.Ketamine = [.8 .1 .1];
GP.Colors.LID = [.2 .8 .1];
GP.Colors.LeftPaw = [.7 .4 .2];
GP.Colors.RightPaw = [.2 .4 .7];
GP.Colors.Nose = [.4 .7 .2];
GP.Colors.IMU = [.2 .7 .7];

% File paths and directories.
switch user
    case 'Gabe'
        % Probably easiest to just hard-code your directories here...
        GP.DIRS.Data_Dir = 'C:\Data\string_pull_compact';
        GP.DIRS.Temp_Dir = 'C:\Temp';
        GP.DIRS.Box_Dir = [];
        GP.DIRS.Analysis_Dir = 'C:\Temp\Analysis_Results';
        if ~exist(GP.DIRS.Analysis_Dir,'dir')
            mkdir(GP.DIRS.Analysis_Dir)
        end
        GP.DIRS.SessionList_File = fullfile(Git_dir, 'String_Pull_312A', 'SessionInfo.xlsx');
        GP.DIRS.LFP_Dir = []; % sometimes these are so big that they will not be in a local folder.
        GP.DIRS.Video_Dir =  []'; % sometimes these are so big that they will not be in a local folder.
    case 'Stephen'
        username=getenv('USERNAME');
        if exist('E:\Data\String_Pull_Rm312a','dir')
            GP.DIRS.Data_Dir = 'E:\Data\String_Pull_Rm312a';
            GP.DIRS.Temp_Dir = 'E:\Temp';
            GP.DIRS.Box_Dir = ['C:\Users\' username '\Box\Cowen Laboratory'];
            GP.DIRS.Analysis_Dir = fullfile(Dropbox_dir,'\Foldershare\Analysis_Results_Dropbox');
            GP.DIRS.SessionList_File = fullfile(Git_dir, 'String_Pull_312A', 'SessionInfo.xlsx');
            GP.DIRS.LFP_Dir = []; % sometimes these are so big that they will not be in a local folder.
            GP.DIRS.Video_Dir =  []'; % sometimes these are so big that they will not be in a local folder.
        elseif exist('G:\Data\string_pull_compact','dir')
            GP.DIRS.Data_Dir = 'G:\Data\string_pull_compact';
            GP.DIRS.Temp_Dir = 'G:\Temp';
            GP.DIRS.Box_Dir = ['C:\Users\' username '\Box\Cowen Laboratory'];
            GP.DIRS.Analysis_Dir = fullfile(Dropbox_dir,'\Foldershare\Analysis_Results_Dropbox');
            GP.DIRS.SessionList_File = fullfile(Git_dir, 'String_Pull_312A', 'SessionInfo.xlsx');
            GP.DIRS.LFP_Dir = []; % sometimes these are so big that they will not be in a local folder.
            GP.DIRS.Video_Dir =  []'; % sometimes these are so big that they will not be in a local folder.

        elseif exist('C:\Data\string_pull_compact\', 'dir')

            % Set up the locations for all of the important directories and files.
            % Do not create new DIRS varibles unless we all agree upon them
            GP.DIRS.Data_Dir = 'C:\Data\string_pull_compact\';
            GP.DIRS.Temp_Dir = 'C:\Temp';

            GP.DIRS.Box_Dir = ['C:\Users\' username '\Box\Cowen Laboratory'];
            GP.DIRS.Analysis_Dir = fullfile(Dropbox_dir,'\Foldershare\Analysis_Results_Dropbox');
            GP.DIRS.SessionList_File = fullfile(Git_dir, 'String_Pull_312A', 'SessionInfo.xlsx');
            GP.DIRS.LFP_Dir = []; % sometimes these are so big that they will not be in a local folder.
            GP.DIRS.Video_Dir =  []'; % sometimes these are so big that they will not be in a local folder.

        elseif strcmp(username,'Stephen Cowen')
            % Set up the locations for all of the important directories and files.
            % Do not create new DIRS varibles unless we all agree upon them
            GP.DIRS.Data_Dir = ['C:\Users\' username '\Box\Cowen Laboratory\Data\LID_Ketamine_Single_Unit_R56'];
            GP.DIRS.Temp_Dir = 'C:\Temp';

            GP.DIRS.Box_Dir = ['C:\Users\' username '\Box\Cowen Laboratory'];
            GP.DIRS.Analysis_Dir = fullfile(Dropbox_dir,'\Foldershare\Analysis_Results_Dropbox');
            v = 'Z:\Data\String_Pull_312a\RECORDING_SESSIONS\SessionInfo.xlsx';
            if exist(v,'file')
                GP.DIRS.SessionList_File = v;
            else
                GP.DIRS.SessionList_File = fullfile(Git_dir, 'String_Pull_312A', 'SessionInfo.xlsx');
            end
            GP.DIRS.LFP_Dir = []; % sometimes these are so big that they will not be in a local folder.
            GP.DIRS.Video_Dir =  []'; % sometimes these are so big that they will not be in a local folder.
        elseif strcmp(username,'cowen')
            v = 'cowen';
            %     GP.DIRS.Data_Dir = 'E:\Data\String_Pull_312a\RECORDING_SESSIONS\';
            %     GP.DIRS.Data_Dir = 'E:\Data\String_Pull_Rm312a';
            GP.DIRS.Data_Dir = 'D:\Temp\string_pull_compact';
            GP.DIRS.Temp_Dir = 'C:\Temp';

            GP.DIRS.Box_Dir = ['C:\Users\' v '\Box\Cowen Laboratory'];
            GP.DIRS.Analysis_Dir = fullfile(Dropbox_dir,'\Foldershare\Analysis_Results_Dropbox');
            GP.DIRS.SessionList_File = ['Z:\Data\String_Pull_312a\RECORDING_SESSIONS\SessionInfo.xlsx'];
            GP.DIRS.LFP_Dir = []; % sometimes these are so big that they will not be in a local folder.
            GP.DIRS.Video_Dir =  []'; % sometimes these are so big that they will not be in a local folder.
        else
            error('could not find the specific identity of this computer/user')
        end
end
% disp ([' Added DIRS global variable for ' v])
GP.fnames.paw_file = 'Filtered_Time_Stamped_Coordinates.mat';
GP.fnames.imu_file = 'Inertial_data.mat';
GP.fnames.spike_file = 'AllSpikes.mat';
GP.fnames.event_file = 'EVT.mat';
GP.fnames.pos_file = 'POS.mat';
GP.fnames.meta_file = 'Meta_data.mat';
% GP.fnames.session_info_file = 'SessionInfo.xlsx';
GP.fnames.string_pull_intervals_file = 'good_string_pull_intervals_uSec.mat';

%%%%%%%%%%%%%%%%

