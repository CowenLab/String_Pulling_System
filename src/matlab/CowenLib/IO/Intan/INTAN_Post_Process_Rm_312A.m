function INTAN_Post_Process_Rm_312A(intan_data_dir, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract events, LFP, inertial data by default.
%  NOTE: code for synchronizing top and front camera video can be found in:
%  INTAN_Post_Process_Rm_312A_top_camera.m and
%  INTAN_Post_Process_Rm_312A_front_camera.m
% These two functions can be run from this function or independently as
% long as the INTAN data (e.g., event data, LFP) has been processed
% previously.
%
%  This function can synchronize data from top-down and front camera if that data is
%  saved in the directory above the INTAN saved directory
%    for example if '\Rat 333\3\Rec_210818_101300' is the INTAN directory,
%    then you MUST put the front camera data in...
%
%
%    ???? Need to figure this out.
%
%  For this to work, make sure the PRM.extract_position and/or
%  PRM.extract_front_camera are set to true
%
% NOTES:
% Assumes you are using the NEW Intan updated acquisition system as of
% 2021. It may crash if you use the old acquisition system so don't do
% that.
%
% INPUT:
%   intan_data_dir - the root directory where the INTAN data was stored
%     for example: 'Z:\Data\String_Pull_312a\RECORDING SESSIONS\Rat 333\3\Rec_210818_101300'
%   extra args...
%   set different PRM. variables to change what occurs in this code.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Variables
%
% Important digital input files/pins.
DINfile.top_camera_frame = 'board-DIGITAL-IN-10.dat'; % for the top down camera.
DINfile.front_camera_frame = 'board-DIGITAL-IN-15.dat'; % for the front facing camera.
DINfile.rotary_encoder = 'board-DIGITAL-IN-12.dat'; % rotary encoder
DINfile.treadmill = []; %
DINfile.feeder_click = []; % TTL from the feeder indicating when rat was fed.

% Parameters: typcially you will not change these, but possibly.
PRM.extract_lfp = true; % make an ./LFP folder and put a subset of downsampled .dat data into that folder as matlab files.
PRM.extract_imu = true; % make an ./LFP folder and put a subset of downsampled .dat data into that folder as matlab files.
PRM.extract_events = true; % often I only do this if I decide to spike sort.
PRM.perform_CAR_filt = false; % often I only do this if I decide to spike sort.
PRM.estimate_TTL_from_dat = true;
PRM.ttl_thresh = 5500;

PRM.CM_PER_TIC_ROTARY_ENCODER = .3432; % Est. Double check. Presumes the current pully wheel size.

PRM.LFP_sFreq = 1000; % Desired sampling frequency for LFP
PRM.IMU_sFreq = 200; % desired output frequency for the IMU data
% PRM.sync_top_camera = false; % Sync the .csv file produced by deeplabcut to the INTAN timestamps.
% PRM.sync_front_camera = false; % Sync the .csv file produced by deeplabcut to the INTAN timestamps.
% PRM.extract_all_DIN_times = true; % extract from every DIN file in the folder. Adds some extra time.

Extract_varargin(); % This will override the above defaults if the user passes in name-value pairs into the function.
% Run for muliple directories if so desired.
if iscell(intan_data_dir)
    for ii = 1:length(intan_data_dir)
        INTAN_Post_Process_Rm_312A(intan_data_dir{ii}, varargin)
    end
    return
end

% Other variables...
event_out_file = fullfile(intan_data_dir,'EVT.mat');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Housekeeping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
delete(fullfile(intan_data_dir,'time.dat'))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load and save the meta data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
IF = read_Intan_RHD2000_file_cowen(intan_data_dir,'info.rhd');
fs_initial = IF.frequency_parameters.amplifier_sample_rate;

% Determine the n records...
ff = find_files(fullfile(intan_data_dir,'amp-*.dat'));
fp = fopen(ff{1},'rb');
ok = fseek(fp,0,'eof');
id = ftell(fp);
fclose (fp);
META.sFreq_amp = IF.frequency_parameters.amplifier_sample_rate;
META.sFreq_aux = IF.frequency_parameters.aux_input_sample_rate;
META.nRecs = id/2;
META.sec_of_recording = META.nRecs/META.sFreq_amp;
META.RHD_CH = [IF.amplifier_channels.chip_channel]; % This corresponds to the numbers in the file name. THIS STARTS WITH ZERO

save(fullfile(intan_data_dir,'Meta_data'),'META','IF');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Process event data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if PRM.extract_events
    EVT = [];
    ff = find_files(fullfile(intan_data_dir,'board-DIGITAL-IN-*.dat'));
    if ~isempty(ff)
        disp('Extracting events from every DIN file.')
        for iF = 1:length(ff)
            [~,nm] = fileparts(ff{iF});
            nm = strrep(nm,'-','_');
            EVT.(nm) = INTAN_Extract_Times_From_DIN( ff{iF} );
            fprintf('.')
        end
        fields = fieldnames(DINfile);
        % if ~exist(event_out_file,'file')
        for iF = 1:length(fields)
            if ~isempty(DINfile.(fields{iF}))
                fname = fullfile(intan_data_dir, DINfile.(fields{iF}));
                [~,just_name] = fileparts(fname);
                just_name = strrep(just_name,'-','_');
                %         if length(dir(fname)) == 1
                EVT.([fields{iF} '_recnum']) = EVT.(just_name);
                %             EVT.([fields{iF} '_recnum']) = INTAN_Extract_Times_From_DIN( fname );
                EVT.([fields{iF} '_uS']) = 1e6*(EVT.([fields{iF} '_recnum'])/META.sFreq_amp);
                % used to use INTAN_Extract_Transitions but this did not
                % deliver end times and was strangly complicated.
                %         else
                %             disp([' Could not find ' fname])
                %         end
                fprintf('e%d ',iF);
            end
        end
        EVT.System_sFreq = double(IF.frequency_parameters.amplifier_sample_rate);
        save(event_out_file,'EVT');
        disp('Saved EVT.mat file.')
        % Compress the DIN files as they just take up useless space.
        zip(fullfile(intan_data_dir, 'DIN_FILES'),ff);
        delete(fullfile(intan_data_dir,'board-DIGITAL-IN*.dat'))
    else
        load(fullfile(intan_data_dir,'EVT.mat'))
    end
end
%% ROTARY ENCODER
if ~isempty(DINfile.rotary_encoder)
    % This generates a nice plot of the rotary encoder motion.
    LK_Rotary_Encode_Speed(EVT, META)
    title('Rotary Encoder Speed/Acc')
    
    saveas(gcf,'Rotary_Encoder_Output.png')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save LFP data if required...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if PRM.extract_lfp
    mkdir(fullfile(intan_data_dir,'LFP'))
    ff = find_files(fullfile(intan_data_dir,'amp-*.dat'));
    skip = 2;
    nrecs = [];
    LFP = [];
    cnt = 1;
    for iF = 1:skip:length(ff)
        [~,fname] = fileparts(ff{iF});
        fp = fopen(ff{iF},'rb');
        D = fread(fp,'int16');
        fclose(fp);
        LFP.data = int16(resample(D,PRM.LFP_sFreq, fs_initial));
        LFP.to_uV_conversion = 0.195; % to microvolts
        LFP.LFP_sFreqj = PRM.LFP_sFreq;
        LFP.original_sFreq = fs_initial;
        LFP.fname = ff{iF};
        
        nrecs(cnt) = length(D);
        save(fullfile(intan_data_dir,'LFP',[fname '_LFP']),'LFP')
        fprintf('.')
        cnt = cnt + 1;
    end
    % Save timestamps for each record in the data.
    if min(abs(diff(nrecs))) > 2
        error('rec size not equal among files')
    end
    n_lfp_recs = length(LFP.data);
    t_uS = 1e6*((0:(n_lfp_recs-1))/PRM.LFP_sFreq + .5/PRM.LFP_sFreq);
    
    save(fullfile(intan_data_dir,'LFP','LFP_times'),'t_uS')
    
    disp('Saved LFP data')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save INERTIAL data...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ff = find_files(fullfile(intan_data_dir,'aux-*.dat'));
if isempty(ff)
    % Assume that we are re-running the code and the aux files have been
    % zipped up. So, unzip them.
    disp('Unzipping AUX Files')
    unzip(fullfile(intan_data_dir,'AUX_FILES.zip'),intan_data_dir);
    ff = find_files(fullfile(intan_data_dir,'aux-*.dat'));
end
if PRM.extract_imu
    % Find the file sizes
    dat_files = find_files(fullfile(intan_data_dir,'amp-*.dat'));
    d_dat = dir(dat_files{1});
    good_imu_files = false(1,length(ff));
    for iF = 1:length(ff)
        d(iF) = dir(ff{iF});
        if d(iF).bytes == d_dat.bytes
            good_imu_files(iF) = true;
        end
    end
    if any(good_imu_files == false)
        disp('WARNING: IMU conversion for at least one file failed')
    end
    IMU = [];
    for iF = 1:length(ff)
        if good_imu_files(iF)
            [~,fname] = fileparts(ff{iF});
            fp = fopen(ff{iF},'rb');
            D = fread(fp,'uint16');
            fclose(fp);
            IMU.data_V(:,iF) = resample(D,PRM.IMU_sFreq, fs_initial)';
        else
            IMU.data_V(:,iF) = nan;
        end
        IMU.IMU_sFreq = PRM.IMU_sFreq;
        IMU.original_sFreq = fs_initial;
        IMU.fname{iF} = ff{iF};
        fprintf('.')
    end
    IMU.data_V = IMU.data_V * 0.0000374; % to volts
    IMU.data_V = single(IMU.data_V);
    n_imu_recs = Rows(IMU.data_V);
    IMU.t_uS = 1e6*((0:(n_imu_recs-1))/PRM.IMU_sFreq + .5/PRM.IMU_sFreq);
    % Save the IMU to a .mat file
    save(fullfile(intan_data_dir,'Inertial_data'),'IMU')
    % Zip up the big AUX files and delete the originals
    if ~exist(fullfile(intan_data_dir,'AUX_FILES.zip'),'file')
        zip(fullfile(intan_data_dir, 'AUX_FILES'),ff);
    end
    delete(fullfile(intan_data_dir,'aux-*.dat'))
    disp('Saved IMU data')
end
% Zip or delete the time file - seems useless to me...
if exist(fullfile(intan_data_dir,'time.dat'),'file')
    zip(fullfile(intan_data_dir,'TIME'),fullfile(intan_data_dir,'time.dat'));
    delete(fullfile(intan_data_dir,'time.dat'))
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Common average rereference data and filter for spike extraction.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if PRM.perform_CAR_filt
    ff = find_files(fullfile(intan_data_dir,'amp-*.dat'));
    INTAN_Common_Avg_Reref_Filt_for_Spikes(ff,true)
end

