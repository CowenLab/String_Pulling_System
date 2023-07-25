% INTAN Post Processing Script

% Designed to work with the "One File Per Channel" Format.
% Start the recording with the Intan system, then start saving your
% position and (optionally) video file in the folder it produces. 

% Run this in the directory where the data was saved.
% It will do everything in situ. Make sure the position file is in this
% directory and that there are no spaces in the directory tree.

function INTAN_Post_Process()

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Set User-parameters, Get Filenames, Make Sure Environment is Kosher
master_TicID = tic;
SKIP_EVENT_EXTRACTION = false; 
SKIP_ACCEL = false; %On-board accelerometers

%Event Channel names -- These should be the values in the "Custom Channel
%Name" string for each digital input channels. You can change these to
%something like "DIN-07" if you didn't name them in the amplifier software.
SYNCHNAME = 'VIDEO_SYNCH';
EVENTNAME = 'EVENT';
STROBENAME = 'IMU_STROBE'; %Functions exist for processing the IMU data and can be incorporated into this script
SIGNAME = 'IMU_SIG'; %Right now we'll just make sure to get the raw IMU synch data based on these labels

LFP_sFreq = 1E4; %What we will resample the LFP channels at. 10000 seems reasonable.

masterBatch = 'C:\Users\scowen.Cowen-W7SSD\Dropbox\CowenLab\!Projects\Intan_system';
copyfile(masterBatch,pwd); %get the kkwik batch file

[~, SessName, ~] = fileparts(pwd);  %Get unique session identifier from name.
header_file = 'info.rhd'; %default intan system header contains all amplifier metadata
ch_translation_master = 'C:\Users\Stephen\DropBox\CowenLab\!Projects\Intan_system\Pinouts-EIB and headstage\Channel_translation_table_Fertambieu_128_EIB_to_Amplipex_and_Intan.xlsx';

f_info = dir(header_file);
if isempty(f_info)
    beep
    beep
    msgbox(['NO HEADER: You may be in the wrong directory'])
    return
end
[p,data_root,e] = fileparts(header_file);

% if (exist('amplifier.dat') || exist('auxiliary.dat') || exist('supply.dat'))
%     beep
%     beep
%     error('Wrong Data Format. ("File Per Signal Type") Use/make a different post-processing script. Detected format is compatible with Neuroscope.')
%     msgbox(['Wrong Data Format. ("File Per Signal Type") Use/make a different post-processing script. Detected format is compatible with Neuroscope.'])
%     return
% end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
%Find the tracking position file
d = dir(fullfile(pwd, ['*.pos']));
if isempty(d)
    msgbox('no position data')
    position_file = [];
else
    [m,ix] = max([d.datenum]); % Takes the most recent position data.
    tmp_file = d(ix).name; % assumes it's the most recent file.
    position_file = fullfile(pwd,tmp_file);
end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Import Metadata

% Import amplifier data header. This contains all the metadata and also
% provides a handy index of channel filenames, as they are formatted
% the same as the "Native Channel Name."
IF = INTAN_Read_RHD_file(header_file,1); %Loads the metadata in verbose mode

% Assign Time Vector File
tFile = 'time.dat';

% Assign Sampling Frequencies
sFreq = IF.frequency_parameters.amplifier_sample_rate;
startRecID_Offset = findStartRecID(tFile,sFreq)-1; %Will equal zero unless the data files have been created with the "triggered recording" option.
RecID_to_uSec_conversion = 1e6/sFreq;
%LFP resampling frequency set at the top.
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Produce Summary Channel Translation Table

% This is mostly for the purposes of producing an updated, human-readable
% table verifying the session configuration--The important information
% is all saved in the amplifier metadata.
% This table can also be fed into the "INTAN_Generate_Settings" function to
% update an amplifier settings file with this channel configuration.

%Grab copy of template from dropbox.
ch_translation_full_path_fname = fullfile(pwd,['channel_configuration_' SessName '.xlsx']);
copyfile(ch_translation_master,ch_translation_full_path_fname);

%Update copy according to channel configuration
INTAN_Update_Channel_Trans_Table(ch_translation_full_path_fname);

%Load this table and save it with the metadata.
TT = INTAN_Load_Channel_Trans_Table(ch_translation_full_path_fname);
save('session metadata','IF','TT','startRecID_Offset');
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Load the behavior events.
% This is similar to the AMPX script since, while slow and not terribly
% efficient, it takes the big sparse data files and turns them into dense
% collections of transition timestamps. A c program that differences a dat
% file with an offset version of itself would be a speedier option.


% Find Event Channels
VideoSynchChannel = findIntanBoardChannelsByName(SYNCHNAME,IF,'digital in');
Event_Ch = findIntanBoardChannelsByName(EVENTNAME,IF,'digital in');
IMU_strobe_Ch = findIntanBoardChannelsByName(STROBENAME,IF,'digital in');
IMU_sig_Ch = findIntanBoardChannelsByName(SIGNAME,IF,'digital in');

EVT_usec = [];
EVT_recID = [];
StrobeRecIDs = [];
SigRecIDs = [];
VideoSyncRecIDs = []; 
VideoSyncTimeStamps =[];

if SKIP_EVENT_EXTRACTION
    disp('Skipping Event Extraction')
else
    %%Extract Event Codes
    if (exist(Event_Ch,'file'))
        disp('Getting Behavioral Events Records')
        RawEventRecIDs = INTAN_Extract_Transitions(Event_Ch);
        if ~isempty(RawEventRecIDs)
            EVT_recID = Events_from_transition_times(RawEventRecIDs);
            EVT_usec(:,1) = (EVT_recID(:,1)-startRecID_Offset)*RecID_to_uSec_conversion;
        end
        save('EVT_RAW_usec.mat','EVT_usec', 'EVT_recID')
    end
    
    
    %%Extract IMU System Channels
    if(exist(IMU_strobe_Ch,'file') && exist(IMU_sig_Ch,'file'))
        disp('Extracting Event Records for the IMU system');
        StrobeRecIDs = INTAN_Extract_Transitions(IMU_strobe_Ch);
        SigRecIDs = INTAN_Extract_Transitions(IMU_sig_Ch);
        save('IMU_events_recID.mat', 'StrobeRecIDs','SigRecIDs')
    end
    
    
    %%Extract Video Synch Channel
    if(exist(VideoSynchChannel,'file'))
        disp('Extracting Video Sync Indices.');
        VideoSyncRecIDs = INTAN_Extract_Transitions(VideoSynchChannel);
        if ~isempty(VideoSyncRecIDs)
            VideoSyncTimeStamps = (VideoSyncRecIDs(:,1)-startRecID_Offset)*RecID_to_uSec_conversion;
        end
        save('VideoSyncTimes_RAW.mat', 'VideoSyncTimeStamps','VideoSyncRecIDs')
    end
    
end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Get the position data.

if(~isempty(position_file) && ~SKIP_EVENT_EXTRACTION)
    
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
    
    %Note that there are no provisions for the user starting the tracking
%before they start the recording
    save('Pos.mat','pos')
end

%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Process On-Board Accelerometer Data
if ~SKIP_ACCEL
    % Subtract gravity correction/adjust for sensitivity for each file
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
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Remove DC from amplifier channels
INTAN_Remove_DC_From_Amplifier_Channels(IF);
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Resample LFP channels and give them their own time vector.
% If Reference_Ch is specified, re-references them, too.

INTAN_Extract_LFP(IF,LFP_sFreq);
% Move LFPs to their own directory
if ~isempty(dir('*.datlfp'))
    if ~exist('LFP','dir')
        mkdir('LFP')
    end
    movefile('*.datlfp','LFP')
    movefile('time_LFP.dat','LFP')
    copyfile(header_file,'LFP')
end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Get Spikes using UltraMegaSort2000
INTAN_Extract_Spikes(IF,sFreq,startRecID_Offset);
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Cluster Cut
% Run the bat file in situ. If hard drive space is a concern have it move
% the files like the AMPX script does.

disp('Getting ready to KKwik!!!!111oneelevenpointninerecurringlimx->0sinx/x')
addpath(genpath(fullfile(Home_dir,'MClustSE_v3.1_temp')));
% READY TO KKWICK!!!
RunClustBatch2('Batch2.txt')
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Wrap-Up
total_time_sec = toc(master_TicID);
infoTime = dir(tFile);
hrs_of_data = infoTime.bytes/sFreq/4/60/60;
msgbox([ 'INTAN_Post_Process: Postprocessing took a total of ' num2str(total_time_sec/60/60) ' hrs to complete for ' num2str(hrs_of_data) ' hrs of recorded data.  ' pwd ])

end %End of Post-Processing Function
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         ( ( ( (
%                          ) ) ) )  
%                         ( ( ( (
%                          ) ) ) )
%                         I I I I
%                         N N N N
%                         T T T T
%                         A A A A
%                        _N N N N_ 
%                        | | | | | 
%                        {=|===|=} 
%                          |||||
%                      __  \\|//  __
%                     (  ) _| |_ (  )
%                      ~~    "    ~~
%                       (  0   0  )
%      -----------ooO----(       )----Ooo------------
%                 '''     (     )     '''
%                          (   )
%                           \ /
%                          ~~O~~