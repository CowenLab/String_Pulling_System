%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Master script for all post-processing in room 334
% Have the AVT tools in your path.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Cowen 2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Edit these file/directories for each session. BE CAREFUL.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EXTRACT_SPIKES = true; % set to true if you want to extract spikes as well.
SESSION_TOP_DIR = 'C:\Data\LID_Ketame_Single_Unit_R56';
% SESSION_TOP_DIR = 'C:\Data\ACUTE_DANA';
addpath(SESSION_TOP_DIR)

RAT = '396';
SESSION = '15';
INTAN_DATA_DIR = 'Recording_221206_110500';
POS_FILE = '\\MRMANHATTAN\E Video Tracking\Rat396\15\15_221206-111931.pos'; % top down camera password on this computer is 1ketamine2
% POS_FILE = '';
FRONT_TRACK_VIDEO_FILE = ''; % unused until we get the other machine up and running.
MASTER_BACKUP_DIR = 'G:\LID_Ketame_Single_Unit_R56';
MASTER_BOX_DATA_DIR = 'C:\Users\Goku\Box\Cowen Laboratory\Data\LID_Ketamine_Single_Unit_R56';
% MASTER_BOX_DATA_DIR = 'C:\Users\Goku\Box Sync\Cowen Laboratory\Data\ACUTE_DANA';
MCLUST_DIR = 'C:\Users\Goku\Box\Cowen Laboratory\Src_sub\matlab\Mclust_4_CowenMods';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Construct the file paths to the main directories.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SESSION_DATA_DIR = fullfile(SESSION_TOP_DIR,['Rat' RAT],SESSION);
DATA_RAW_DIR = fullfile(SESSION_DATA_DIR, INTAN_DATA_DIR);
DATA_PROCESSED_DIR = fullfile(SESSION_DATA_DIR, [INTAN_DATA_DIR '_processed_cor_chan_map']);
BACKUP_DIR = fullfile(MASTER_BACKUP_DIR,['Rat' RAT],SESSION);
BOX_DATA_DIR = fullfile(MASTER_BOX_DATA_DIR,['Rat' RAT],SESSION);
d = dir(fullfile(SESSION_DATA_DIR,'*channel_map_TT*.txt'));
if length(d) ~= 1
    d
    error('Could not find channel map file or there is more than one')
end
CHAN_MAP_FILE = fullfile(SESSION_DATA_DIR,d(1).name);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Basic post-processing
% Needs to have the Intan and AVT paths to run
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    addpath(genpath(MCLUST_DIR))

INTAN_Post_Process_Rm_334(DATA_RAW_DIR,POS_FILE)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Needs to have the Mclust paths to run.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if EXTRACT_SPIKES
    % CAR - rereference and filter spikes.
    ff = find_files(fullfile(DATA_RAW_DIR,'amp-*.dat'));
    INTAN_Common_Avg_Reref_Filt_for_Spikes(ff,true)
    
    addpath(genpath(MCLUST_DIR))
    
    MC_run_klustakwik(DATA_RAW_DIR,DATA_PROCESSED_DIR,CHAN_MAP_FILE, 'Prefix', 'filt_CAR_', 'SpikeFilterType', 'none')
    
%     ff_spikes = find_files(fullfile(DATA_PROCESSED_DIR,'*.spikes'));
%     MC_Clean_Outlier_Spikes(ff_spikes,99.95,'delete','')

    %     for iF = 1:length(ff)
    %         zip(fullfile(DATA_DIR, 'AMP'),ff);
    %     delete(fullfile(DATA_RAW_DIR,'amp-*.dat'));
    %     % The car files are not really needed after spike extraction.
    delete(fullfile(DATA_RAW_DIR,'filt_CAR_*.dat'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Backup some relevant code.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
A = [];
A{1} = which('INTAN_Post_Process_Rm_334_master');
A{2} = which('INTAN_Post_Process_Rm_334');
A{3} = which('MC_run_klustakwik');
zip(fullfile(DATA_RAW_DIR,'mfiles'),A)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compress the front camera video
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run either FormatFactory or HandBrake - DO NOT USE MATLAB as matlab
% compression is waaaaayyy too slow.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Backup the data to the internal hard drive.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Backing up data. This can take forever so be patient.')
tic
copyfile(SESSION_DATA_DIR, BACKUP_DIR)
toc/3600
disp(['Done copying to... ' BACKUP_DIR])
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Copy the .spikes and smaller files (e.g., position, events...) to Box
% % for spike sorting and analysis...
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 disp('Copying to box.')
if ~exist(BOX_DATA_DIR,'dir')
    mkdir(BOX_DATA_DIR)
end
copyfile(fullfile(SESSION_DATA_DIR,'*.docx'),BOX_DATA_DIR);
copyfile(fullfile(SESSION_DATA_DIR,'*.txt'),BOX_DATA_DIR);
copyfile(fullfile(SESSION_DATA_DIR,'*.xls*'),BOX_DATA_DIR);
copyfile(fullfile(SESSION_DATA_DIR,'..','*.xls*'),BOX_DATA_DIR);
copyfile(fullfile(DATA_RAW_DIR,'*.mat'),BOX_DATA_DIR);
copyfile(fullfile(DATA_RAW_DIR,'*.pos'),BOX_DATA_DIR);
copyfile(fullfile(DATA_RAW_DIR,'*.rhd'),BOX_DATA_DIR);
[~,PD] = fileparts(DATA_PROCESSED_DIR);
copyfile(DATA_PROCESSED_DIR,fullfile(BOX_DATA_DIR,PD));

% 
