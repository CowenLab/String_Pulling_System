function NPXL_Post_Process(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%EVT.
% TO KNOW:
% You should probably run this function through NPXL_Post_Process_Run.m
% instead of directly.
%
% This program will run catGT and filter and start kilosort if desired.
% You will still need to run tprime after spike sorting.
%
% Expects:
% C:\CatGT-win
% C:\TPrime-win
% C:\Users\CowenLab\Documents\GitHub\Kilosort-2.5

% NOTE: Only anlalyze .ap and .lf files that have been run through CatGT as
% CatGT does shifting which corrects for small changes in inter-channel
% alignment. I forgot about this. CatGT will also produce an alignment .txt
% file for the .ap file and the code here will also provide a .txt file for
% ALL analog channels going into the nidq system. 
% The other thing that is expected is a 3 column comma separated file that
% has the channel, matlab friendly event name, notes. it must be called
% 'event_codes.csv'. This is used when TPrime runs to create an Events.mat
% file that has the events nicely named (e.g., stim_times, scan_times....).
% 
% In theory, it is not necessary to run gblcar or loccar in CatGT as the matlab
% based software called here should do this, but it also should not hurt.
%
% Be sure to find bad channels before you run this and specify them here.
%
% EXAMPLE CALL: 
% NPXL_Post_Process('PRM_ROOT_DATA_DIR','C:\Data\DANA_NAc_Acute\Rat411\1112022_DANA_REAL_g0','PRM_BAD_CHANNEL_LIST_imec0',[325])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%EVT.
% Cowen 2022
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%EVT.
PRM_ROOT_DATA_DIR = pwd; % assume you are running in the current directory. This directory should end in _g0.
PRM_BAD_CHANNEL0_LIST = []; % This is ZERO based as you would see in SpikeGLX so be sure the first channel is zero.
PRM_TEMP_FOLDER_LOCATION = 'C:\Temp\SpikeSorting';

%Which Commands to run
PRM_CREATE_TCAT_FILE = true; % make false if you already created this file on a previous run to save some time.
PRM_CREATE_LF_FILE=true;
PRM_COPY_FILES=true;
PRM_CREATE_CHANNELMAP=true; 
PRM_RUN_DENOISE=true;
PRM_RUN_KILOSORT=true;


%Cat GT Parameters for events
PRM_EVENT_CHANNELS=[5]; %Analog Signal on Channel 5
PRM_XA_Duration = [0]; %Duration of analog pulse 0 will extract everything
PRM_INAROW=3; % No. of signals reqd for detecting signal 3 prevents noise but shorter signals need 2.
PRM_XA_THR1=0.8;%Threshold for detecting xa (in V)
PRM_XA_THR2=0.5; %Secondary threshold for detetcting xa (in V) -keep lower than THR1 for square pulses

%Channel Map Parameters
%PRM_chanMapPath='';
%PRM_chanMapFile'';

Extract_varargin;

[~,root_folder] = fileparts(PRM_ROOT_DATA_DIR);
AP_FILE_DIR = fullfile(PRM_ROOT_DATA_DIR, [root_folder '_imec0']);
disp(['Running in ' PRM_ROOT_DATA_DIR])
disp('REMINDER: You should view the data files with SpikgGLX before running')
disp('to make sure you found all of the bad channels before running.')

if ~exist(PRM_TEMP_FOLDER_LOCATION, 'dir')
    mkdir(PRM_TEMP_FOLDER_LOCATION)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Change if ANALOG Parameters were added in Post_Process_Run- SS changes
NPXL_Extract_Events_With_CatGT_SS('PRM_ROOT_DATA_DIR', PRM_ROOT_DATA_DIR,...
     'PRM_EVENT_CHANNELS',PRM_EVENT_CHANNELS,...
        'PRM_XA_Duration',PRM_XA_Duration,...
        'PRM_INAROW',PRM_INAROW,...
        'PRM_XA_THR1',PRM_XA_THR1,...
        'PRM_XA_THR2',PRM_XA_THR2);

 if PRM_CREATE_LF_FILE
     NPXL_Process_LF_With_CatGT('PRM_ROOT_DATA_DIR', PRM_ROOT_DATA_DIR,...
      'PRM_BAD_CHANNEL0_LIST', PRM_BAD_CHANNEL0_LIST)
 end

if PRM_CREATE_TCAT_FILE
    disp('Running CatGT. Might take a while.')
    [tcat_ap_file] = NPXL_Process_AP_With_CatGT('PRM_ROOT_DATA_DIR', PRM_ROOT_DATA_DIR, ...
        'PRM_BAD_CHANNEL0_LIST', PRM_BAD_CHANNEL0_LIST);
else
    % assume that it already exists. Get the fname
    d = dir(fullfile(AP_FILE_DIR,'*tcat*.ap.bin'));
    if length(d)>1
        d
        error('more than one ap tcat file')
    end
    tcat_ap_file = fullfile(AP_FILE_DIR,d(1).name)
end
tcat_meta_file = strrep(tcat_ap_file,'.ap.bin','.ap.meta');

% New file for processing...
    [~,n,ext] = fileparts(tcat_ap_file);
    dest_ap_fname = fullfile(PRM_TEMP_FOLDER_LOCATION,[ 'denoise_' n ext] );
    dest_meta_fname = strrep(dest_ap_fname,'.ap.bin','.ap.meta');
if PRM_COPY_FILES
    % Copy to the SSD or temp dir for cleaning and spike sorting.
    disp('Copying ap.bin to temp directory for processing.')
    copyfile_xcopy(tcat_meta_file,dest_meta_fname);
    copyfile_xcopy(tcat_ap_file,dest_ap_fname);
    

    % save some info that might help copying the processed data back home.
    save([dest_ap_fname '.mat'],'tcat_ap_file','tcat_meta_file','AP_FILE_DIR','PRM_ROOT_DATA_DIR')

    fprintf('Copied from %s to %s \n', PRM_ROOT_DATA_DIR, dest_ap_fname)
end

if PRM_CREATE_CHANNELMAP
    tcat_meta_file_name=regexp(tcat_meta_file,'((?<=imec0\\).*(?=.meta))','match');
    tcat_meta_file_name=strrep(tcat_meta_file_name,'.ap','.ap.meta');

    [PRM_chanMapFile,PRM_chanMapPath]=SGLXMetaToCoords_SS('metaName',tcat_meta_file_name{1},'metaFilePath',AP_FILE_DIR);
    PRM_CHANNEL_MAP_FILE=fullfile(PRM_chanMapPath,PRM_chanMapFile);
    fprintf('Channel Map created in location  %s \n', PRM_CHANNEL_MAP_FILE)
end

% Would be good to get the rms of the file before sending here for
% reference
if PRM_RUN_DENOISE
    NPXL_Denoise_ap_bin_file('PRM_BIN_FNAME', dest_ap_fname,...
        'PRM_ADDITIONAL_BAD_CHANNELS0',PRM_BAD_CHANNEL0_LIST,...
        'CHANNEL_MAP_FILE',PRM_CHANNEL_MAP_FILE);
        
end


% NOW it is conceivable to delete the original .ap and .lf bin files as the
% tcat will take over.
disp('Check the _tcat files. If they are good, you can probably delete the original ap.bin and lf.bin files.')

% When you complete spike sorting, be sure to copy the results back to the
% original data folder.
if PRM_RUN_KILOSORT
    NPXL_RunKilosort_2_SS('PRM_TEMP_FOLDER_LOCATION',PRM_TEMP_FOLDER_LOCATION,...
        'PRM_chanMapPath',PRM_chanMapPath,'PRM_chanMapFile',PRM_chanMapFile,...
        'PRM_BIN_FNAME',dest_ap_fname)
end

%
if 0 % Junk but might be good as a reference
    nidq_meta_fname = find_files([PRM_ROOT_DATA_DIR '\*.nidq.meta']);
    [~,root_nidq_name] = fileparts(nidq_meta_fname{1});
    binName = [root_nidq_name '.bin'];
    metaName = [root_nidq_name '.meta'];
    nidq_meta = obj.ReadMeta(metaName,PRM_ROOT_DATA_DIR);
    nidq_sFreq = str2double(nidq_meta.niSampRate);
    ch_ix = 1:7; % these are not the actual channel numbers in the file- but the indices. I know, confusing.
    EVT.channel_ix = ch_ix;
    thresh_V = 1.5;

    % read in all the ANALOG data.
    dataArray = obj.ReadBin(0, inf, nidq_meta, binName, PRM_ROOT_DATA_DIR);
    dataArray = SGLX_Class.GainCorrectNI(dataArray, ch_ix, nidq_meta);
    dataArray = dataArray(ch_ix,:);
    dataArray_dig = single(dataArray > thresh_V);
    EVT.up_ix = cell(Rows(dataArray_dig),1);
    EVT.up_t_uS = cell(Rows(dataArray_dig),1);
    EVT.down_ix = cell(Rows(dataArray_dig),1);
    EVT.down_t_uS = cell(Rows(dataArray_dig),1);
    for iR = 1:Rows(dataArray_dig)
        EVT.up_ix{iR} = find(diff(dataArray_dig(iR,:))==1) + 1;
        EVT.up_t_uS{iR} = 1e6*EVT.up_ix{iR}/nidq_sFreq;
        EVT.down_ix{iR} = find(diff(dataArray_dig(iR,:))==-1) + 1;
        EVT.down_t_uS{iR} = 1e6*EVT.down_ix{iR}/nidq_sFreq;
    end
    if 0
        clf
        subplot(2,1,1)
        plot(dataArray_dig(1,:))
        hold on
        plot(dataArray_dig(2,:))
        subplot(2,1,2)
        plot(EVT.up_t_uS{1}/1e6,zeros(size(EVT.up_t_uS{1})),'o')
        hold on
        plot(EVT.up_t_uS{2}/1e6,1 + zeros(size(EVT.up_t_uS{2})),'g>')
    end
    save(fullfile(PRM_ROOT_DATA_DIR,'Events.mat'),'EVT')

    % Compress
    zip(fullfile(PRM_ROOT_DATA_DIR,[binName '.zip']),fullfile(PRM_ROOT_DATA_DIR,binName))
    if exist(fullfile(PRM_ROOT_DATA_DIR,[binName '.zip']),"file")
        delete(fullfile(PRM_ROOT_DATA_DIR,binName))
    end

    % % Load the meta data...
     obj = SGLX_Class;
     meta = obj.ReadMeta(meta_ap_fname,DATA_DIR);
     sFreq = str2double(meta.imSampRate); % NOTE: use SpikeGLX to get the 'true' rate and update the meta file. It will be a non-integer rate.
     if sFreq == 30000
         % How to import the true sampling rate?
         disp('WARNING: it appears that the headstage sFreq was not calibrated as sFreq is exactly 30000.')
     end

end
