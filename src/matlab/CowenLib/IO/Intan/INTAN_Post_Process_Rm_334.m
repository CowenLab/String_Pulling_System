function INTAN_Post_Process_Rm_334(DATA_DIR, POS_FILE, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do everything but spike extraction.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Variables
DINfile.pos_strobe_ID = 'board-DIN-10.dat'; %9
DINfile.pos_unique_code_ID = 'board-DIN-09.dat'; %8
DINfile.pos_frame_ID = 'board-DIN-11.dat'; %10
DINfile.front_camera_frame_ID = 'board-DIN-15.dat'; % for the front facing camera.
DINfile.rotary_encoder_ID = 'board-DIN-12.dat'; % rotary encoder
DINfile.treadmill_ID = 'board-DIN-14.dat'; % rotary encoder
PIX_PER_CM = nan; % This is not known yet. Needs to be determined.
LFP_sFreq = 500;

PRM.extract_position = true;
PRM.extract_lfp = true;
PRM.perform_CAR_filt = false; % often I only do this if I decide to spike sort. 

process_varargin(varargin); % This will override the above defaults if the user passes in name-value pairs into the function.
% Other variables...
event_out_file = fullfile(DATA_DIR,'EVT.mat');
pos_out_file = fullfile(DATA_DIR,'POS.mat');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Housekeeping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
delete(fullfile(DATA_DIR,'*DOUT*.dat'))
delete(fullfile(DATA_DIR,'vdd*.dat'))
delete(fullfile(DATA_DIR,'board-ADC*.dat'))
% copy over position file if it is not already saved in data directory...
if ~exist(fullfile(POS_FILE),'file')
    disp('POSITION FILE DOES NOT EXIST!!! Skipping.')
    PRM.extract_position = true;
end

[~,fname,ext] = fileparts(POS_FILE);

if ~exist(fullfile(DATA_DIR,fname),'file')
    copyfile(POS_FILE,DATA_DIR)
    disp('Copied pos file to local data dir folder.')
    POS_FILE = fullfile(DATA_DIR,[fname ext]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load and save the meta data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
IF = INTAN_Read_RHD_file(fullfile(DATA_DIR,'info.rhd')); %IF will contain meta data on the Intan session
fs_initial = IF.frequency_parameters.amplifier_sample_rate;

% Determine the n records...
ff = find_files(fullfile(DATA_DIR,'amp-*.dat'));
fp = fopen(ff{1},'rb');
ok = fseek(fp,0,'eof');
id = ftell(fp);
fclose (fp);
META.sFreq_amp = IF.frequency_parameters.amplifier_sample_rate;
META.sFreq_aux = IF.frequency_parameters.aux_input_sample_rate;
META.nRecs = id/2;
META.sec_of_recording = META.nRecs/META.sFreq_amp;
META.RHD_CH = [IF.amplifier_channels.chip_channel]; % This corresponds to the numbers in the file name. THIS STARTS WITH ZERO

save(fullfile(DATA_DIR,'Meta_data'),'META','IF');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Process event data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ff = find_files(fullfile(DATA_DIR,'*DIN*.dat'));
if ~isempty(ff)
    fields = fieldnames(DINfile);
    % if ~exist(event_out_file,'file')
    for iF = 1:length(fields)
         fname = fullfile(DATA_DIR, DINfile.(fields{iF}));
         %         fname = DINfile.(fields{iF});
        if exist(fname,'file')
            EVT.(fields{iF}) = INTAN_Extract_Times_From_DIN( fname );
            % used to use INTAN_Extract_Transitions but this did not
            % deliver end times and was strangly complicated.
        else
            disp([' Could not find ' fname])
        end
        fprintf('e%d ',iF);
    end
    EVT.System_sFreq = IF.frequency_parameters.amplifier_sample_rate;
    save(event_out_file,'EVT');
    disp('Saved EVT.mat file.')
    % Compress the DIN files as they just take up useless space.
    zip(fullfile(DATA_DIR, 'DIN_FILES'),ff);
    delete(fullfile(DATA_DIR,'*DIN*.dat'))
else
    load(fullfile(DATA_DIR,'EVT.mat'))
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process tracking data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if PRM.extract_position
    P = dlmread(POS_FILE,'\t',1);
    POS = [];
    if abs(Rows(P)-length(EVT.pos_frame_ID)) > 5
        disp('problems. video recording might have been started before recording or continued after recording was turned off')
        disp('Assuming first record is OK.')
    end
    df = Rows(P) - length(EVT.pos_frame_ID);
    if df >= 0
        P(1:length(EVT.pos_frame_ID),8) = EVT.pos_frame_ID;
    else
        P(:,8) = EVT.pos_frame_ID(1:Rows(P));
    end
    P(:,9) = 1e6*P(:,8)/fs_initial;
    GIX = P(:,9) > 0;
    P = P(GIX,:);
    POS.Time_uS = P(:,9);
    POS.RecID = P(:,8);
    POS.Red_xy = P(:,1:2); 
    POS.Green_xy = P(:,3:4); 
    POS.Blue_xy = P(:,5:6);
    POS.Speed_Red = [];
    if sum(sum(sum(POS.Red_xy)))> 10
        POS.Speed_Red = Speed_from_xy([ POS.Time_uS POS.Red_xy],[],1);
    end
    POS.Speed_Green = [];
    if sum(sum(sum(POS.Green_xy)))> 10
        POS.Speed_Green = Speed_from_xy([ POS.Time_uS POS.Green_xy],[],1);
    end
    
    POS.Red_xy = single(POS.Red_xy);
    POS.Green_xy = single(POS.Green_xy);
    POS.Blue_xy = single(POS.Blue_xy);
    POS.Speed_Red = single(POS.Speed_Red);
    POS.Speed_Green = single(POS.Speed_Green);
    
    save(pos_out_file,'POS')
    
    figure(1)
    subplot(2,2,1:2)
    plot(POS.Time_uS/3600e6,POS.Green_xy(:,1),'Color',[.1 .9 .1]);
    hold on
    plot(POS.Time_uS/3600e6,POS.Green_xy(:,2),'Color',[.2 .8 .1]);
    plot(POS.Time_uS/3600e6,POS.Red_xy(:,1),'Color',[.9 .1 .1]);
    plot(POS.Time_uS/3600e6,POS.Red_xy(:,2),'Color',[.8 .2 .2]);
    xlabel('Hours')
    axis tight
    subplot(2,2,3)
    plot(POS.Red_xy(:,1),POS.Red_xy(:,2),'r.','MarkerSize',1)
    hold on
    plot(POS.Green_xy(:,1),POS.Green_xy(:,2),'g.','MarkerSize',1)
    axis tight
    subplot(2,2,4)
    if ~isempty(POS.Speed_Red)
        plot(POS.Time_uS/3600e6,POS.Speed_Red,'r')
    end
    hold on
    if ~isempty(POS.Speed_Green)
        plot(POS.Time_uS/3600e6,POS.Speed_Green,'g')
    end
    axis tight
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save LFP data if required...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if PRM.extract_lfp
    mkdir(fullfile(DATA_DIR,'LFP'))
    ff = find_files(fullfile(DATA_DIR,'amp-*.dat'));
    skip = 2;
    nrecs = [];
    LFP = [];
    cnt = 1;
    for iF = 1:skip:length(ff)
        [~,fname] = fileparts(ff{iF});
        fp = fopen(ff{iF},'rb');
        D = fread(fp,'int16');
        fclose(fp);
        LFP.data = int16(resample(D,LFP_sFreq, fs_initial));
        LFP.to_uV_conversion = 0.195; % to microvolts
        LFP.LFP_sFreqj = LFP_sFreq;
        LFP.original_sFreq = fs_initial;
        LFP.fname = ff{iF};
        
        nrecs(cnt) = length(D);
        save(fullfile(DATA_DIR,'LFP',[fname '_LFP']),'LFP')
        fprintf('.')
        cnt = cnt + 1;
    end
    % Save timestamps for each record in the data.
    if min(abs(diff(nrecs))) > 2
        error('rec size not equal among files')
    end
    n_lfp_recs = length(LFP.data);
    t_uS = 1e6*((0:(n_lfp_recs-1))/LFP_sFreq + .5/LFP_sFreq);
    
    save(fullfile(DATA_DIR,'LFP','LFP_times'),'t_uS')
    
    disp('Saved LFP data')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save INERTIAL data...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ff = find_files(fullfile(DATA_DIR,'aux-*.dat'));
if isempty(ff)
    % Assume that we are re-running the code and the aux files have been
    % zipped up. So, unzip them.
    disp('Unzipping AUX Files')
    unzip(fullfile(DATA_DIR,'AUX_FILES.zip'),DATA_DIR);
    ff = find_files(fullfile(DATA_DIR,'aux-*.dat'));
end

IMU_sFreq = 200;
IMU = [];
for iF = 1:length(ff)
    [~,fname] = fileparts(ff{iF});
    fp = fopen(ff{iF},'rb');
    D = fread(fp,'uint16');
    fclose(fp);
    IMU.data_V(:,iF) = resample(D,IMU_sFreq, fs_initial)';
    IMU.IMU_sFreq = IMU_sFreq;
    IMU.original_sFreq = fs_initial;
    IMU.fnam{iF} = ff{iF};
    fprintf('.')
end
IMU.data_V = IMU.data_V * 0.0000374; % to volts
IMU.data_V = single(IMU.data_V);
n_imu_recs = Rows(IMU.data_V);
IMU.t_uS = 1e6*((0:(n_imu_recs-1))/IMU_sFreq + .5/IMU_sFreq);
save(fullfile(DATA_DIR,'Inertial_data'),'IMU')
if ~exist(fullfile(DATA_DIR,'AUX_FILES.zip'),'file')
    zip(fullfile(DATA_DIR, 'AUX_FILES'),ff);
end
delete(fullfile(DATA_DIR,'aux-*.dat'))
disp('Saved IMU data')
% Zip or delete the time file - seems useless to me...
if exist(fullfile(DATA_DIR,'time.dat'),'file')
    zip(fullfile(DATA_DIR,'TIME'),fullfile(DATA_DIR,'time.dat'));
    delete(fullfile(DATA_DIR,'time.dat'))
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Common average rereference data and filter for spike extraction.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if PRM.perform_CAR_filt
    ff = find_files(fullfile(DATA_DIR,'amp-*.dat'));
    INTAN_Common_Avg_Reref_Filt_for_Spikes(ff,true)
end

