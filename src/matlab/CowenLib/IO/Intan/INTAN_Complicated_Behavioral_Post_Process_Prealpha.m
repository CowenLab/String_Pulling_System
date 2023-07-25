% INTAN Post Processing Script
% Adapted from/Modeled after/Blatantly stolen out of AMPX_Post_Process.m
% Designed to work with the "One File Per Channel" Format.

% Would actually probably work if you made sure the directories behaved
% right. Just use 'INTAN_Post_Process'

function INTAN_Post_Process_Behavior()

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Set User-parameters, Get Filenames, Make Sure Environment is Kosher
master_TicID = tic;

STAGE_REACHED = 0; % basically analogous to AMPX stages
UPDATE_TRANSLATION_TABLE = true; %Produce Summary Translation Table
SKIP_EVENT_EXTRACTION = true; 
SKIP_ACCEL = true; %On-board accelerometers
SKIP_IMU = true; %External IMU

%Event Channel names -- These should be the values in the "Custom Channel
%Name" string for each digital input channels. You can change these to
%something like "DIN-07" if you didn't name them in the amplifier software.
SYNCHNAME = 'VIDEO_SYNCH';
EVENTNAME = 'EVENT';
STROBENAME = 'IMU_STROBE';
SIGNAME = 'IMU_SIG';

Reference_Ch = [];
LFP_sFreq = 1E4;

header_file = 'info.rhd';
dest_data_dir = 'E:\Data\FakeRat101';
lab_book_file = 'C:\Users\Stephen\Dropbox\CowenLab\Rat_running_check_daily_Rm_334';
batch_txt_file = 'E:\Data\Batch1.txt';
base_trans_table = 'Channel_translation_table_Fertambieu_128_EIB_to_Amplipex_and_Intan.xlsx';
post_processing_src_code_dir = fileparts(which('INTAN_Post_Process'));
dropbox_root = 'C:\Users\Stephen\Dropbox\CowenLab\';

f_info = dir(header_file);
if isempty(f_info)
    beep
    beep
    msgbox(['NO DATA FILE: You may be in the wrong directory'])
    return
end
[p,data_root,e] = fileparts(header_file);

if (exist('amplifier.dat') || exist('auxiliary.dat') || exist('supply.dat'))
    beep
    beep
    error('Wrong Data Format. ("File Per Signal Type") Use a different post-processing script. This format is compatible with Neuroscope.')
    msgbox(['Wrong Data Format. ("File Per Signal Type") Use a different post-processing script. This format is compatible with Neuroscope.'])
    return
end

% Extract the Rat ID and session from the current directory name.
current_data_dir = pwd;
ix = strfind(current_data_dir,'Rat');
[rat_ID_string, sess_str]= strtok(current_data_dir(ix:end),'\');
sess_str = sess_str(2:end);
rat_ID = str2double(rat_ID_string(4:end));
sess_num = str2double(sess_str);

%Load the lab book
[X,T] = xlsread(lab_book_file);
ix = find(X(:,1)==rat_ID & X(:,3) == sess_num);
if isempty(ix)
    msgbox([ 'NO LAB BOOK ENTRY IN ' lab_book_file])
    LabBook = [];
else
    LabBook.Researcher = T{ix+1,10};
    LabBook.Notes = T{ix+1,11};
    LabBook.Weight_Grams = X(ix,4);
    LabBook.Date = T{ix+1,1};
    LabBook.Behavioral_Protocol = T{ix+1,6};
    save('LabBook','LabBook')
end

% Create an 'id' file whos only purpose is to store the rat number and
% session - this can then be copied into subfolders to ensure that if a
% subfolder is moved around and separated from the original data, it can always be linked back to the original
% data.
ID_FILE = ['Rat_' num2str(rat_ID) '_ses_' num2str(sess_num) '.ID'];
fp = fopen(ID_FILE,'w'); fclose(fp);

% Determine the destination data directory.
final_data_dir = fullfile(dest_data_dir,rat_ID_string,sess_str);
current_root_data_dir = strrep(current_data_dir,sess_str,'');
final_root_data_dir = strrep(final_data_dir,sess_str,'');

behavior_data_dir = [dropbox_root '\Data\Rat_Behavior_Data'];
IMU_data_dir = [dropbox_root '\Data\Rat_IMU_Data'];
IMU_mat_file = fullfile(p,['IMU.mat']);
IMU_data_file = [];
behavior_data_file = [];
position_file = [];
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
%% Find the text files that contain the PUTTY data from the IMU and events.
% AMPX Copy-paste job so we can use the same rat seamlessly on both systems

d = dir(fullfile(behavior_data_dir, ['rat*.log']));
if isempty(d)
    msgbox('no behavior data')
    behavior_data_file = [];
else
    [m,ix] = max([d.datenum]); % Takes the most recent data.
    tmp_file = d(ix).name; % assumes it's the most recent file.
    if str2double(tmp_file(17:18)) ~= str2double(f_info.date(1:2))
        disp('Looks like the behavior data file does not exist'); msgbox('Looks like the behavior data file does not exist');
        behavior_data_file = [];
    else
        behavior_data_file = fullfile(behavior_data_dir,tmp_file);
    end
end

d = dir([IMU_data_dir '\*.log']);
if isempty(d)
    msgbox('no IMU data')
    IMU_data_file = [];
else
    [m,ix] = max([d.datenum]);
    tmp_file = d(ix).name; % assumes it's the most recent file.
    if str2double(tmp_file(12:13)) ~= str2double(f_info.date(1:2))
        disp('Looks like the IMU data file does not exist'); msgbox('Looks like the IMU data file does not exist');
        IMU_data_file = [];
    else
        IMU_data_file = fullfile(IMU_data_dir,tmp_file);
    end
end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
%Find the position file
d = dir(fullfile(pwd, ['*.pos']));
if isempty(d)
    msgbox('no position data')
    position_file = [];
else
    [m,ix] = max([d.datenum]); % Takes the most recent position data.
    tmp_file = d(ix).name; % assumes it's the most recent file.
    if str2double(tmp_file(17:18)) ~= str2double(f_info.date(1:2))
        disp('Looks like the position data file does not exist'); msgbox('Looks like the position data file does not exist');
        position_file = [];
    else
        position_file = fullfile(behavior_data_dir,tmp_file);
    end
end

STAGE_REACHED = 1;
save('Post_Process_Matlab_State.mat');
save('Post_process_stage_reached.mat','STAGE_REACHED');
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
%% Copy the files over to the current directory.
% AMPX Copy/paste job

if ~isempty(behavior_data_file)
    if exist(behavior_data_file,'file')
        copyfile(behavior_data_file,pwd)
    end
end

copyfile(batch_txt_file,pwd)

if ~isempty(IMU_data_file)
    if exist(behavior_data_file,'file')
        copyfile(IMU_data_file,pwd)
    end
    [p,n,e] = fileparts(IMU_data_file);
    IMU_data_file = [n e];
end

% Copy all of the experiment control code over - good insurance policy.
if exist('ZBasic','dir')
    mkdir('ZBasic')
end
copyfile([dropbox_root '\Src_sub\Experiment_Control\ZBasic\*.bas'],fullfile(pwd,'ZBasic'))
% Save the code that did the post processing so that we can always go
% back and reconstruct how the data was extracted (in case errors are
% found later on)
if exist('Post_process_code','dir')
    mkdir('Post_process_code')
end
copyfile([post_processing_src_code_dir '\*.m'],fullfile(pwd,'Post_process_code'))
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Import Metadata

% Import amplifier data header. This contains all the metadata and also
% provides a handy index of channel filenames, as they are formatted
% the same as the "Native Channel Name."
IF = INTAN_Read_RHD_file(header_file,1);

% Assign Time Vector File
tFile = 'time.dat';
% Assign Sampling Frequencies
sFreq = IF.frequency_parameters.amplifier_sample_rate;
startRecID_Offset = findStartRecID(tFile,sFreq)-1; %Will equal zero unless the data files have been created with the "triggered recording" option.
RecID_to_uSec_conversion = 1e6/sFreq;

% Find Event Channels
VideoSynchChannel = findIntanBoardChannelsByName(SYNCHNAME,IF,'digital in');
Event_Ch = findIntanBoardChannelsByName(EVENTNAME',IF,'digital in');
IMU_strobe_Ch = findIntanBoardChannelsByName(STROBENAME,IF,'digital in');
IMU_sig_Ch = findIntanBoardChannelsByName(SIGNAME,IF,'digital in');
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Update Channel Translation Table

% This is mostly for the purposes of producing an updated, human-readable
% table verifying the session configuration--The important information
% is all saved in the amplifier metadata.
% This table can also be fed into the "INTAN_Generate_Settings" function to
% update an amplifier settings file with this channel configuration.

if UPDATE_TRANSLATION_TABLE
    ch_translation_base_full_path_fname = fullfile(dropbox_root,base_trans_table);
    ch_translation_full_path_fname = fullfile(pwd,['channel configuration' rat_ID '_' sess_num '.xlsx']);
    
    copyfile(ch_translation_base_full_path_fname,ch_translation_full_path_fname);
    INTAN_Update_Channel_Trans_Table(ch_translation_full_path_fname);
end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Load the behavior events.
% This is similar to the AMPX script since, while slow and not terribly
% efficient, it takes the big sparse data files and turns them into dense
% collections of transition timestamps. A c program that differences a dat
% file with an offset version of itself would be a speedier option.

EVT_usec = [];
EVT_recID = [];

if SKIP_EVENT_EXTRACTION
    msgbox('Skip Event Extraction')
else
    tic
    disp('Getting Behavioral Events Records')
    RawEventRecIDs = INTAN_Extract_Transitions(Event_Ch);
    if ~isempty(RawEventRecIDs)
        EVT_recID = Events_from_transition_times(RawEventRecIDs);
        EVT_usec(:,1) = (EVT_recID(:,1)-startRecID_Offset)*RecID_to_uSec_conversion;
    end
    save(event_mat_file,'EVT_usec', 'EVT_recID')
    toc
    tic
    disp('Extracting Event Records for the IMU system');
    StrobeRecIDs = INTAN_Extract_Transitions(IMU_strobe_Ch);
    SigRecIDs = INTAN_Extract_Transitions(IMU_sig_Ch);
    save('IMU_events_recID.mat', 'StrobeRecIDs','SigRecIDs')
  
    %Process Video Synch Channel
    disp('Extracting Video Sync Indices.');
    VideoSyncRecIDs = INTAN_Extract_Transitions(VideoSynchChannel); 
    VideoSyncTimeStamps = (VideoSyncRecIDs(:,1)-startRecID_Offset)*RecID_to_uSec_conversion;
    
    save('VideoSyncTimes.mat', 'VideoSyncTimeStamps','VideoSyncRecIDs')
    
    toc
end

STAGE_REACHED = 2;
save('Post_Process_Matlab_State.mat');
save('Post_process_stage_reached.mat','STAGE_REACHED');
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Load IMU sync events. <- AMPX-Copy/Paste Job for now
if exist(IMU_data_file,'file')
    d = dir(IMU_data_file);
else
    d = [];
end

if ~isempty(IMU_data_file) && ~SKIP_IMU && d.bytes > 2000
    % Save the raw IMU data first...
    try
        tic
        [RAW_IMU] = IMU_read_log_from_arduino_um6(IMU_data_file);
        toc
        save('Raw_IMU','RAW_IMU');
        INTAN_Extract_IMU([], RAW_IMU, StrobeRecIDs, SigRecIDs, IF);
    catch
        disp('Skipping IMU data. CRASHED ON IMU.')
    end
else
    RAW_IMU = [];
    disp('Skipping IMU DATA.')
end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Process On-Board Accelerometer Data
if ~SKIP_ACCEL
    % Subtract gravity correction from each file.
    INTAN_Extract_Accel(IF);
    % Move Accelerometer files to their own directory
    if ~isempty(dir('*.datacc'))
        if ~exist('ACCEL','dir')
            mkdir('ACCEL')
        end
        movefile('*.datacc','ACCEL')
        copyfile(header_file,'ACCEL')
    end
else
    disp('Skipping On-board Accelerometer Data.')
end

STAGE_REACHED = 3;
save('Post_Process_Matlab_State.mat');

save('Post_process_stage_reached.mat','STAGE_REACHED');
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Remove DC from amplifier channels
tic
for i = 1:numel(IF.amplifier_channels)
    curFile = strcat('amp-',IF.amplifier_channels(i).native_channel_name,'.dat');
    if (exist(curFile));
        Remove_DC(curFile);
    end
end
toc
STAGE_REACHED = 4;
save('Post_Process_Matlab_State.mat');

save('Post_process_stage_reached.mat','STAGE_REACHED');
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Resample LFP channels and give them their own time vector.
% If Reference_Ch is specified, re-references them, too.
tic
INTAN_Extract_LFP(IF,LFP_sFreq,Reference_Ch);
% Move LFPs to their own directory
if ~isempty(dir('*.datlfp'))
    if ~exist('LFP','dir')
        mkdir('LFP')
    end
    movefile('*.datlfp','LFP')
    movefile('time_LFP.dat','LFP')
    copyfile(header_file,'LFP')
end
toc

STAGE_REACHED = 6;
save('Post_Process_Matlab_State.mat');

save('Post_process_stage_reached.mat','STAGE_REACHED');
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Get the position data.

if(~isempty(position_file))
    
    pos = AVT_Process_Tracking_Log(position_file);
    
    extraframes = length(VideoSyncRecIDs-length(pos.ElapsedTime));
    if (extraframes > 0)
        %Handle case where camera had a frame in the buffer as it was commanded to stop
        %This results in one extra TTL pulse at the end, and happens because we
        %have the TTL trigger off the exposure, not the frame readout, ensuring
        %that the timestamps supplied to the processing software are accurate
        %to when the images were taken.
        
        VideoSyncRecIDs = VideoSyncRecIDs(1:end-extraframes);
        VideoSyncTimeStamps = VideoSyncRecIDs(1:end-extraframes);
        save('VideoSyncTimes.mat', 'VideoSyncTimeStamps','VideoSyncRecIDs');
    elseif(extraframes <0)
        %Handle case where user stops recording before they stop tracking.
        len = length(pos.ElapsedTime)+extraframes;
        pos.ElapsedTime = pos.ElapsedTime(1:len);
        if(isfield(pos,'Red'))
            pos.Red = pos.Red(:,1:len);
        end
        if(isfield(pos,'Green'))
            pos.Green = pos.Green(:,1:len);
        end
        if(isfield(pos,'Blue'))
            pos.Blue = pos.Blue(:,1:len);
        end
    end
end
%Note that there are no provisions for the user starting the tracking
%before they start the recording

save('Pos.mat','pos')
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Plot Events to make sure the processing worked.
% Basically a Copy-Paste Job from AMPX--does the same thing.

if isempty(EVT_usec) || isempty(position_file)
else
    u = unique(EVT_recID(:,2));
    SF = cell(length(u),1);
    P = [VideoSyncTimeStamps,pos.Red(:,1),Pos.Red(:,2)];
    for iEvt = 1:length(u)
        %
        IX = EVT_recID(:,2) == u(iEvt);
        [SF{iEvt}] = ScatterFields_cowen(P, EVT_recID(IX,1));
        %
    end
    
    % plot the events.
    figure
    plot(P(:,2),P(:,3),'k.')
    hold on
    colors = jet(length(u));
    for iEvt = 1:length(u)
        plot(SF{iEvt}(:,2),SF{iEvt}(:,3),'.','Color',colors(iEvt,:));
        if size(SF{iEvt},1) > 1
            xy = nanmean(SF{iEvt}(:,2:3));
        else
            xy = SF{iEvt}(:,2:3);
        end
        text(xy(1),xy(2),num2str(u(iEvt)),'Color',colors(iEvt,:),'BackgroundColor',[.7 .7 .7])
    end
    saveas(gcf,'Plot_xy_and_events','png')
end
STAGE_REACHED = 7;
save('Post_Process_Matlab_State.mat');
save('Post_process_stage_reached.mat','STAGE_REACHED');
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Get Spikes using UltraMegaSort2000
INTAN_Extract_Spikes(IF,TT,sFreq,startRecID_Offset);

STAGE_REACHED = 8;
save('Post_Process_Matlab_State.mat');
save('Post_process_stage_reached.mat','STAGE_REACHED');
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
%Move files to storage drive
if strcmpi(current_data_dir,final_data_dir) == 0
    % Only copy if we aren't already in this directory.
    disp(['Copying files to ' final_data_dir])
    copyfile(current_data_dir, final_data_dir);
end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Cluster Cut
% Copy-Paste Job from AMPX Script--does the same thing.

disp('Getting ready to KKwik!')
cd (final_data_dir)
cd Cluster_cutting
addpath(genpath(fullfile(Home_dir,'MClustSE_v3.1_temp')));
% READY TO KKWICK!!!
RunClustBatch2('Batch1.txt')
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Wrap-Up
total_time_sec = toc(master_TicID);
infoTime = dir(tFile);
hrs_of_data = infoTime.bytes/sFreq/4/60/60;
msgbox([ 'INTAN_Post_Process: Postprocessing took a total of ' num2str(total_time_sec/60/60) ' hrs to complete for ' num2str(hrs_of_data) ' hrs of recorded data.  ' pwd ])

end %End of Post-Processing Function
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%