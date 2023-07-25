function INTAN_Post_Process(CTRL)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function INTAN_Post_Process(CTRL)
% adapted from AMPX_Post_Process and INTAN_Post_Process_Acute
% ASSUMES YOU ARE RUNNING IN THE DIRECTORY WITH THE DATA. ASSUMES THAT
% THERE IS A CHANNEL TRANSLATION TABLE AND POSITION FILE IN THIS DIRECTORY.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen/Rauscher 2015
% Cowen - adapted for LRRK2 setup and for extracting inertial data if there
% is some.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if nargin < 1
    % Default post processing
    CTRL.COMPRESS_TESTDAT = false; % zips up the dat file at the end.
%     CTRL.FIND_BAD_CHANNELS = false; % auto bad channel detection - it needs to be supervised.
    CTRL.SKIP_EVENT_EXTRACTION = true; % Only do this if no events were collected
    CTRL.REMOVE_BASELINE = false; % Remove baseline from .dat file. Don't do this if it has been done already - it takes a long time.
    CTRL.EXTRACT_LICKOMETER_DATA = false;
    CTRL.EXTRACT_LFP = false; % Resample LFPs marked in translation table.
    CTRL.EXTRACT_SPIKES = false; % Remove baseline from .dat file. Don't do this if it has been done already - it takes a long time.
    CTRL.CREATE_SPIKE2_FILE = true; % this is the .smrx file that spike2 uses.
    CTRL.RUNBATCH = false; % auto cluster at the end.
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
master_TicID = tic; % used to determine how long post processing took.
%% PRELIMINARIES: Figure out some file names...
% find the full path to CowenLab
CowenLab_path = which('INTAN_Post_Process');
ix = strfind(CowenLab_path,'CowenLab');
CowenLab_path = CowenLab_path(1:(ix+7));
header_file = 'info.rhd';
post_processing_src_code_dir = fileparts(which('INTAN_Post_Process'));
STAGE_REACHED = 0; % keeps track of which stage was reached.
f_info = dir(header_file);
if isempty(f_info)
    beep
    beep
    msgbox(['NO INFO.RHD FILE: You may be in the wrong directory'])
    return
end
[p,~] = fileparts(header_file);
[~,header_file_root] = fileparts(pwd);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract the Rat ID and session from the current directory name.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
current_data_dir = pwd;
ix = strfind(current_data_dir,'Rat');
if isempty(ix)
    % Assume that this is a mouse recording
    ix = strfind(current_data_dir,'Mouse');
    [animal_ID_string]= strtok(current_data_dir(ix+5:ix+6),'\');
    ix = strfind(current_data_dir,'Day');
    [sess_str]= strtok(current_data_dir(ix+3:ix+4),'\');
    animal_ID = str2double(animal_ID_string);
    sess_num = str2double(sess_str);
else
    [animal_ID_string, sess_str]= strtok(current_data_dir(ix:end),'\');
    animal_ID = str2double(animal_ID_string(4:end));
    sess_str = sess_str(2:end);
    sess_num = str2double(strtok(sess_str,'\'));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine the destination data directory.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create an 'id' file whos only purpose is to store the rat number and
% session - this can then be copied into subfolders to ensure that if a
% subfolder is moved around and separated from the original data, it can always be linked back to the original
% data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ID_FILE = ['Animal_' num2str(animal_ID) '_ses_' num2str(sess_num) '.ID'];
if ~exist(ID_FILE,'file')
    fp = fopen(ID_FILE,'w'); fclose(fp);
end

d = dir( fullfile('..','Channel_translation*.xlsx'));
if length(d) > 1
    error('too many channel translation tables. There can be only one.')
end
d = dir( fullfile('.','Channel_translation*.xlsx'));
if length(d) > 1
    disp('There already is a channel translation table in this directory. Backing it up.')
    for ii = 1:length(d)
        movefile(d(ii).name,[d(ii).name '.backup'])
    end
end

d = dir('*Channel_translation*.xlsx');
d2 = dir('../*Channel_translation*.xlsx');
if isempty(d)
    if isempty(d2)
        copyfile( fullfile('..','..','Channel_translation*.xlsx'), pwd);
    else
        copyfile( fullfile('..','Channel_translation*.xlsx'), pwd);
    end
end

d = dir( fullfile('.','Channel_translation*.xlsx'));
ch_translation_full_path_fname = fullfile(pwd,d(1).name);
% Copy the position file over to this directory if it's not here already.
d = dir('*.pos');
if isempty(d)
    d = dir('../*.pos');
    try
        copyfile(fullfile('..', d(1).name),pwd);
    catch
        error('Could not find the .pos file. Put it in the local data directory')
    end
end



% behavior_data_dir = [CowenLab_path '\Data\Rat_Behavior_Data'];
event_mat_file = fullfile(p,'EVT_RAW_usec.mat'); % This will eventually disappear.
TTL_mat_file = fullfile(p,'TTL_Events_To_Input_Ports.mat'); % this will store the event data.
INTAN_mat_file = fullfile(p,'INTAN.mat'); % this will store the meta data.
behavior_data_file = [];
STAGE_REACHED = 1; save('Post_Process_Matlab_State.mat'); save('Post_process_stage_reached.mat','STAGE_REACHED');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Copy the files over to the current directory.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('Event_codes.mat','file')
    if exist('../Event_codes.mat','file')
        copyfile('../Event_codes.mat',pwd)
    else
        msgbox('no Event_codes.mat file')
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% copyfile(fullfile(final_root_data_dir,'Rat_meta_data.m'),pwd) % meta data about channels etc...
% Copy all of the experiment control code over - good insurance policy.
if ~exist('ZBasic','dir')
    mkdir('ZBasic')
    copyfile([CowenLab_path '\Src_sub\Experiment_Control\ZBasic\*.bas'],fullfile(pwd,'ZBasic'))
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save the code that did the post processing so that we can always go
% back and reconstruct how the data was extracted (in case erroros are
% found later on)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('Post_process_code','dir')
    mkdir('Post_process_code')
    copyfile([post_processing_src_code_dir '\*.m'],fullfile(pwd,'Post_process_code'))
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%2) Load meta data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
INTAN = INTAN_Load_All_Meta_Data(ch_translation_full_path_fname); % e.g. 'E:\Data\Rat3\AMPX_Parameters_Template_HS54.mat'
INTAN.RAT_ID = animal_ID;
INTAN.SESSION = sess_num;
save(INTAN_mat_file,'INTAN');
sFreq = INTAN.sFreq;
RecID_to_uSec_conversion = 1e6/sFreq;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3) Identify the bad channels and update them in the
% Channel_translation_table....xlsx file (so open this file and edit it).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if CTRL.FIND_BAD_CHANNELS
    disp('Updating Header to reflect translation table');
    INTAN.HEADER = INTAN_Update_Header_From_Trans_Table(INTAN.HEADER,INTAN.CH_ASSIGNMENTS); %removes bad channels listed in TT that might not have been turned off
    disp('Updating Translation table to reflect extant channels.')
    INTAN_Update_Channel_Trans_Table(ch_translation_full_path_fname,INTAN.HEADER); % updates xls file to reflect any new bad/not recorded channels.
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Remove DC from the data file. (took ?? for a 7GB file on a standard HD)
% Slow so may want to combine this with re-refernecing to double-up.
% Checked this - and it does work. Not sure of mmap is really any faster
% than fwrite.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('RemovedDC.txt','file') || CTRL.REMOVE_BASELINE == false
    disp('DC removed previously or we are skipping this part')
else
    disp('Removing DC')
    for i = 1:numel(INTAN.HEADER.amplifier_channels)
        curFile = strcat('amp-',INTAN.HEADER.amplifier_channels(i).native_channel_name,'.dat');
        if (exist(curFile,'file'));
            Remove_DC(curFile);
        end
    end
    fp = fopen('RemovedDC.txt','w');
    fclose(fp);
end
STAGE_REACHED = 1.5; save('Post_Process_Matlab_State.mat'); save('Post_process_stage_reached.mat','STAGE_REACHED');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4) Load the events.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if CTRL.SKIP_EVENT_EXTRACTION
    msgbox('Skip Event Extraction')
    EVT_usec = [];
else
    TTL.EventNames         = {'ZBasic' };
    TTL.EventChannelFname = [INTAN.Event_Ch ] ;
    if ~isempty(TTL.EventNames)
         TTL.EventUpRecIDs = INTAN_Extract_Transitions(TTL.EventChannelFname);
         TTL.EventDownRecIDs  = INTAN_Extract_Transitions(TTL.EventChannelFname,1,1);
        % Convert to timestamps.
        for ii = 1:length(TTL.EventUpRecIDs)
            TTL.EventUpRecTimestamps{ii}   = (TTL.EventUpRecIDs{ii}-1)*RecID_to_uSec_conversion;
            TTL.EventDownRecTimestamps{ii} = (TTL.EventDownRecIDs{ii}-1)*RecID_to_uSec_conversion;
        end
    end
    save(TTL_mat_file,'TTL')
    EVT_recID = []; EVT_usec = [];
    if ~isempty(TTL.EventUpRecIDs{1})
        EVT_recID = Events_from_transition_times(TTL.EventUpRecIDs{1});
        EVT_usec(:,1) = (EVT_recID(:,1)-1)*RecID_to_uSec_conversion;
        EVT_usec(:,2) = EVT_recID(:,2);
    end
    save(event_mat_file,'EVT_usec', 'EVT_recID')
    if isempty(EVT_usec)
        msgbox('EVENTS WERE NOT RECORDED!!! Contact STEPHEN or JP STAT')
        disp('EVENTS WERE NOT RECORDED!!! Contact STEPHEN or JP STAT')
    end
    save('Post_Process_Matlab_State.mat');
end
% Plot a summary of the rat's behavior.
try
    ER_Monitor_Behavior_EVT
    saveas(gcf,'Reversal_Behavior.png')
catch
    msgbox('Could not plot the behavior')
end
STAGE_REACHED = 2; save('Post_Process_Matlab_State.mat'); save('Post_process_stage_reached.mat','STAGE_REACHED');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save the lick-o-meter data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if CTRL.EXTRACT_LICKOMETER_DATA
    disp('Extracting Lickometer output')
    INTAN_DAT_to_LFP(INTAN.Lick_sensor_Ch, INTAN.LFP_sFreq, true, [], 'Lick_ch.datlfp'); %to-do.
    
    d = dir('Lick_*.datlfp');
    fp = fopen(d(1).name,'rb');
    LK = fread(fp,'uint16');
    fclose(fp);
    
    figure(1010)
    plot(LK(1:10:end))
    axis tight
    title(['Lickometer ' d(1).name])
    saveas(gcf,'Lickometer.png')
    clear LK
end
STAGE_REACHED = 3; save('Post_Process_Matlab_State.mat'); save('Post_process_stage_reached.mat','STAGE_REACHED');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Extract LFP from each channel - saves as a separate file.
% This is not complete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if CTRL.EXTRACT_LFP
    disp('Extracting LFP')
    INTAN_Extract_LFP(INTAN.HEADER,INTAN.LFP_sFreq);
    % Move LFPs to their own directory
    if ~isempty(dir('*.datlfp'))
        if ~exist('LFP','dir')
            mkdir('LFP')
        end
        movefile('*.datlfp','LFP')
        movefile('time_LFP.dat','LFP')
        copyfile(header_file,'LFP')
    end
end

STAGE_REACHED = 6;
save('Post_Process_Matlab_State.mat');

save('Post_process_stage_reached.mat','STAGE_REACHED');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Extract the position data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[POS,POSrecids] = INTAN_Extract_POS(INTAN);
save('POS','POS','POSrecids')

j = jet(6);
POS(POS < 10) = nan;
figure
for ii = 2:7
    plot(POS(:,1),POS(:,ii),'Color',j(ii-1,:));
    hold on
end
title('Position over time - all colors')

STAGE_REACHED = 7;

save('Post_Process_Matlab_State.mat');
save('Post_process_stage_reached.mat','STAGE_REACHED');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot the events by position - to verify that the events processed correctly.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(EVT_usec) || isempty(POS)
else
    figure
    subplot(1,2,1)
    INTAN_Plot_Position_And_Events(POS(:,[1 6 7]),EVT_usec);
    title('uSec')
    subplot(1,2,2)
    INTAN_Plot_Position_And_Events([POSrecids POS(:,[6 7])], EVT_recID);
    title('RecID')
    saveas(gcf,'Plot_xy_and_events_whpos_uSec_recid','png')

    if exist('Event_codes.mat','file')
        C = load('Event_Codes.mat');
        for ii = 1:length(C.codes)
            if ~isempty(C.codes{ii})
                fprintf('%d \t %s \n',ii,C.codes{ii})
            end
        end
    end
    saveas(gcf,'Plot_xy_and_events','png')
end

STAGE_REACHED = 7.01;
save('Post_Process_Matlab_State.mat');
save('Post_process_stage_reached.mat','STAGE_REACHED');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create Spike2 file.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if CTRL.CREATE_SPIKE2_FILE
    % Create a .smrx file that has the unfiltered data.
    SPK2_IntanDat_to_SMR_Combine(header_file_root);
    % Treate a smr file that has been filtered and re-referenced for
    % sorting.
    %     position_cols_to_use = [6 7];
    %     SPK2_IntanDat_to_SMR_Combine(header_file_root,'spikes_CAR');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Extracting spikes and creates spike files (and ntt files which may or may
% not be valid - given that they are stored in ints??? may clip data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if CTRL.EXTRACT_SPIKES
    disp('Extracting spikes and creating spike files.')
    copyfile(INTAN_Runbatch_file,pwd)
    INTAN_Extract_Spikes(INTAN.HEADER,INTAN.sFreq,0)
end
STAGE_REACHED = 8;
save('Post_Process_Matlab_State.mat');
save('Post_process_stage_reached.mat','STAGE_REACHED');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compuress the test.dat file.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if CTRL.COMPRESS_TESTDAT
    [~,zipname,~] = fileparts(pwd);
    zip([zipname '.zip'],dir('*.dat'));
end
% Leave it up to the user to delete - for safety.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CLUSTER CUT! (do it from the destination as it requires a lot of hard drive space)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if CTRL.RUNBATCH
    disp('Getting ready to KKwik!')
    cwd = pwd;
    cd (fullfile(Dropbox_dir,'CowenLab','Src_sub','matlab','MClustSE_v3.1_temp'));
    startup
    cd (cwd)
    cd Cluster_cutting
    % READY TO KKWICK!!!
    RunClustBatch2('Batch2.txt')
end
% Remember to run Reassign_cluster_membersKK_all_files_all_dirs when this
% completes.
% e.g.
% Reassign_cluster_membersKK_all_files_all_dirs(n_times,spike_file_extension)
% where spike_file_extension is '.ntt'.
% when done, run MClust and start cluster cutting.
total_time_sec = toc(master_TicID);
infoTime = dir('time.dat');
hrs_of_data = infoTime.bytes/sFreq/4/60/60;
disp([ 'INTAN_Post_Process: Postprocessing took a total of ' num2str(total_time_sec/60/60) ' hrs to complete for ' num2str(hrs_of_data) ' hrs of recorded data.  ' pwd ]);
msgbox([ 'INTAN_Post_Process: Postprocessing took a total of ' num2str(total_time_sec/60/60) ' hrs to complete for ' num2str(hrs_of_data) ' hrs of recorded data.  ' pwd ]);
