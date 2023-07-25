function INTAN_Post_Process_Rm_306(DATA_DIR, PRM)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Post-process single-unit data for the surgery room
% acute only so no postion/inertial data.
% ASSUMES most recent INTAN software (circa 2021)
% Cowen 2021e
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameters.
if nargin < 2
    % ALL THE DEFAULT VALUES
    % Make PRM.DINfile empty if you do not want to extract events.
    %     PRM.DINfile = [];
    PRM.DINfile.opto_stim = 'board-DIGITAL-IN-02.dat'; % list digital in files that have timestamps.

    PRM.LFP_sFreq = 500; % only used if LFP files/folder are created.
    PRM.good_channels = []; % These are channels with decent neural data. Other channels are assumed to be noise so do not use them for sorting or CAR. If empty, assume all channels are good.
    PRM.extract_lfp = false;
    PRM.estimate_TTL_from_dat = true; % if the TTLs were not logged properly, you can estimate them from the artifact. Not ideal, but works in 99% of cases due to the large artifact.
    PRM.estTTL_thresh = 5500; % the ONSET of the TTL artifact is detected.
    PRM.perform_CAR_filt = true; % often I only do this if I decide to spike sort.
    PRM.combine_to_one_dat_file = true; % a single file for all channels (good for kilosort and spike2)
    PRM.delete_car_files = false;
    PRM.artifact_removal = true; % TODO: remove some time around each TTL or event in the data.
    %     PRM.artifact_thresh = PRM.estTTL_thresh*.7; % TODO: remove some time around each global big pulse or event in the data.
    PRM.artifact_padding_ms = 4; % TODO: time before artifact ONSET to remove
end
event_out_file = fullfile(DATA_DIR,'EVT.mat');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Housekeeping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% delete(fullfile(DATA_DIR,'time.dat'))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load and save the meta data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
IF = read_Intan_RHD2000_file_cowen(DATA_DIR,'info.rhd');
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
if ~isempty(PRM.DINfile)
    EVT = [];
    ff = find_files(fullfile(DATA_DIR,'board-DIGITAL-IN-*.dat'));
    if ~isempty(ff)
        disp('Extracting events from every DIN file.')
        for iF = 1:length(ff)
            [~,nm] = fileparts(ff{iF});
            nm = strrep(nm,'-','_');
            EVT.(nm) = INTAN_Extract_Times_From_DIN( ff{iF} );
            fprintf('.')
        end
        fields = fieldnames(PRM.DINfile);
        % if ~exist(event_out_file,'file')
        for iF = 1:length(fields)
            if ~isempty(PRM.DINfile.(fields{iF}))
                fname = fullfile(DATA_DIR, PRM.DINfile.(fields{iF}));
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
        zip(fullfile(DATA_DIR, 'DIN_FILES'),ff);
        delete(fullfile(DATA_DIR,'board-DIGITAL-IN*.dat'))
    else
        load(fullfile(DATA_DIR,'EVT.mat'))
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save LFP data if required...
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
        LFP.data = int16(resample(D,PRM.LFP_sFreq, fs_initial));
        LFP.to_uV_conversion = 0.195; % to microvolts
        LFP.LFP_sFreqj = PRM.LFP_sFreq;
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
    t_uS = 1e6*((0:(n_lfp_recs-1))/PRM.LFP_sFreq + .5/PRM.LFP_sFreq);

    save(fullfile(DATA_DIR,'LFP','LFP_times'),'t_uS')

    disp('Saved LFP data')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Common average rereference data and filter for spike extraction.
% Assumes garbage channels have been deleted.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if PRM.perform_CAR_filt
    ff = find_files(fullfile(DATA_DIR,'amp-*.dat'));
    % eliminate noisy channels from this list.
    good_ff = ff;
    if ~isempty(PRM.good_channels)
        good_ff = []; cnt = 1;
        for ii = 1:length(ff)
            [~,fname] = fileparts(ff{ii});
            ch = str2double(fname(end-2:end));
            if ismember(ch,PRM.good_channels)
                good_ff{cnt} = ff{ii};
                cnt = cnt + 1;
            end
        end
    end
    %     INFO = INTAN_Common_Avg_Reref_Filt_for_Spikes(good_ff,true, true); % filter
    %     out_file = fullfile(DATA_DIR,'Combined_CAR_and_Filtered');
    %     for spikes
    INFO = INTAN_Common_Avg_Reref_Filt_for_Spikes(good_ff,true, false); % DO NOT FILTER FOR SPIKES>

end

if PRM.estimate_TTL_from_dat
    % Something bad happened and the TTLs need to be estimated from the raw
    % data. I think that filtering and absolute val might do it.
    % THIS ASSUMES a CAR.Dat file from runing
    % INTAN_Common_Avg_Reref_Filt_for_Spikes above.
    %     PRM.estTTL_thresh = 5500;
    % PRM.event_duration = 80;
    D = INTAN_Read_DAT_file(fullfile(DATA_DIR,'CAR.dat'));
    %Dfs = Filter_for_spikes(D,META.sFreq_amp);
    Dfl = Filter_for_spikes(D,META.sFreq_amp, [5 7000],'cheby1');
    %     INC = [0;diff(Dfl)>0.1];
    figure
    plot(D);hold on; plot(Dfl);% plot(Dfs)
    if isempty(PRM.estTTL_thresh)
        title('Select Threshold')
        tmp = ginput(1);
        PRM.estTTL_thresh  = tmp(2);
    end
    IX = Dfl > PRM.estTTL_thresh;

    yyaxis right
    plot(IX)
    EVENT_SE = find_intervals(IX,.001);
    n_events = Rows(EVENT_SE);
    title(sprintf('Events: %d\n',n_events))
    EVENT_SE(:,2)-EVENT_SE(:,1)
    diff(EVENT_SE(:,1))
    size(EVENT_SE)

    plot_markers_simple(EVENT_SE);
    try
        load(event_out_file);
    end
    EVT.est_TTL_artifact_bad_IX = IX;
    EVT.est_TTL_start_recID = EVENT_SE(:,1);
    EVT.est_TTL_end_recID = EVENT_SE(:,2);
    EVT.est_TTL_start_sec = EVENT_SE(:,1)/META.sFreq_amp;
    EVT.est_TTL_end_sec = EVENT_SE(:,2)/META.sFreq_amp;
    save(event_out_file,'EVT');
    fp = fopen(fullfile(DATA_DIR,'event_int16.dat'),'wb');
    fwrite(fp,IX* PRM.estTTL_thresh,'int16');
    fclose(fp);
end
if PRM.artifact_removal
    % Fill the artifact times with interpolated points.
    pad = round((PRM.artifact_padding_ms/1000)*META.sFreq_amp);

    BIX = conv(EVT.est_TTL_artifact_bad_IX,ones(pad,1),'same');
    BIX = BIX>0;
    BIX(1:10) = false; % make sure there is something at the beginning or end - otherwise the spline will fail.
    BIX(end-10:end) = false; % make sure there is something at the beginning or end - otherwise the spline will fail.
    
    rec = 1:length(D);
    for iF = 1:length(INFO.list_of_reref_dat_files)
        M = INTAN_Read_DAT_file(INFO.list_of_reref_dat_files{iF});
        % figure(102);clf;plot(M);hold on
        M(BIX) = interp1(rec(~BIX),M(~BIX),rec(BIX),'linear');
        % plot(M);
        INTAN_Write_DAT_file(INFO.list_of_reref_dat_files{iF}, M);

    end
    disp('Filled in TTL stim with linear interpolant.')

end

if PRM.combine_to_one_dat_file
    % Combine these files into a single file. This makes loading into Spike2
    % MUCH easier.
    out_file = fullfile(DATA_DIR,'Combined_CAR');
    INTAN_combine_dat_files(INFO.list_of_reref_dat_files,out_file)
    % Assuming this worked, delete all of the filt_CAR files as they just
    % take up a lot of space.
    if PRM.delete_car_files
        disp('deleting filt_CAR files')
        for ii = 1:length(INFO.list_of_reref_dat_files)
            delete(INFO.list_of_reref_dat_files{ii})
        end
    end
end
% delete(fullfile(DATA_DIR,'CAR.dat'))
delete(fullfile(DATA_DIR,'time.dat'))
