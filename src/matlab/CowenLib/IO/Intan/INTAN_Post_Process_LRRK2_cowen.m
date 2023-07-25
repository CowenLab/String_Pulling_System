function INTAN_Post_Process_LRRK2_cowen()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% From camera position times. These files should not change.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('This function assumes that you are running it in the data directory\nwith all relevant files (e.g, transaltion table and .pos file) copied in this directory.\n');
EVT = []; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A handy helper function to convert a train of record numbers to the
% estimated sampling rate...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RecID_to_rate = @(x) Intan_sFreq/median(diff(x));

d = dir('*.pos');
if isempty(d)
    error('Could not find position file')
else
    pos_file = d(1).name;
end
pos_frame_times_intan_file = 'board-DIN-09.dat'; %
unique_code_pos_intan_file = 'board-DIN-08.dat';% ??? Which channel is this?
strobe_pos_intan_file = 'board-DIN-10.dat';% ??? Which channel is this?
% Channel translation
d = dir( fullfile('.','Channel_translation*.xlsx'));
ch_translation_full_path_fname = fullfile(pwd, d(1).name);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get some meta data. Mousies and Days. Mouse encoded as W or L, day as D.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
p = pwd;
tmp = strsplit(p,'\');
curdir = tmp{end};
ix = strfind(curdir,'_D');
ss = strsplit(curdir(ix+1:end),'_');

META.DirName = curdir;
META.Session = str2double(ss{1}(2:end));
META.Date = []; % Add this in later.

txt = curdir(1:(ix-1));
tmp = strsplit(txt,'_');
META = [];
for ii = 1:length(tmp)
    META.AnimalID(ii) = str2double(tmp{ii}(2:end));
    META.Category{ii} = tmp{ii}(1);
    META.ID{ii} = tmp{ii};
end
% This has all of the meta data including the labels for each channel.
% INTAN = INTAN_Load_All_Meta_Data(ch_translation_full_path_fname); % e.g. 'E:\Data\Rat3\AMPX_Parameters_Template_HS54.mat'
INTAN.HEADER = INTAN_Read_RHD_file('info.rhd',1); %Loads the metadata in verbose mode
META.RHD_CH = [INTAN.HEADER.amplifier_channels.chip_channel]; % This corresponds to the numbers in the file name. THIS STARTS WITH ZERO
CTT = INTAN_Load_Channel_Trans_Table(ch_translation_full_path_fname);
Ch_Labs = [];
for iH = 1:length(META.RHD_CH)
    % Find the item in the CTF that corresponds with the header.
    ix = find(CTT.Amplipex_Channel-1 == META.RHD_CH(iH));
    META.file_name{iH} = sprintf('amp-%s.dat', INTAN.HEADER.amplifier_channels(iH).native_channel_name);
    META.Ch_Labs{iH} = sprintf('%s_%s', CTT.Region_Label{ix},INTAN.HEADER.amplifier_channels(iH).native_channel_name);
    META.sFreq_Ch(iH) = INTAN.HEADER.frequency_parameters.amplifier_sample_rate;
end
% Add in the auxilary channels.
tmp_aux_channels = [INTAN.HEADER.aux_input_channels.chip_channel];
nRec = length(META.Ch_Labs);
for iH = 1:length(tmp_aux_channels)
    META.RHD_CH(nRec+iH) = tmp_aux_channels(iH);
    fname = sprintf('aux-%s.dat', INTAN.HEADER.aux_input_channels(iH).native_channel_name);
    META.file_name{nRec+iH} = fname;
    [~,META.Ch_Labs{nRec+iH}] = fileparts(fname); 
    META.sFreq_Ch(nRec+iH) = INTAN.HEADER.frequency_parameters.amplifier_sample_rate;
end
META.AVT_Camera_Video_Sync_Ch = pos_frame_times_intan_file;
META.bit_to_uvolt_conversion = INTAN.HEADER.bit_to_uvolt_conversion;
META.sFreq_amp = INTAN.HEADER.frequency_parameters.amplifier_sample_rate;
% NOTE: This HAS to be wrong --  INTAN.HEADER.frequency_parameters.aux_input_sample_rate
% because the size of the aux files are THE SAME as the size of the amp
% files. They must be at the same rate unless they are at a higher
% precision which is not the case.
META.sFreq_aux = INTAN.HEADER.frequency_parameters.aux_input_sample_rate;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load and Sync and Save the position data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%position sync times
EVT.intan_pos_frame_recids = INTAN_Extract_Transitions( pos_frame_times_intan_file ); fprintf('.');
EVT.intan_pos_unique_code_recids = INTAN_Extract_Transitions( unique_code_pos_intan_file ); fprintf('.');
EVT.intan_pos_clock_recids = INTAN_Extract_Transitions( strobe_pos_intan_file ); fprintf('.');
save('Sync_times.mat','EVT','META');
% Allied Vision Tech for the Manta Camera.
[~,POS] = AVT_Process_Tracking_Log_4_animals(pos_file, EVT.intan_pos_frame_recids);
SPEED = Speed_from_xy(POS(:,1:3));
SPEED = [POS(:,1) SPEED];
save(fullfile(pwd,'POS.mat'),'POS','SPEED');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Write the position data out as binary files for imporation into the smrx
% file. These files can be deleted afterwards.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get n recs in file.
fp = fopen(META.file_name{1},'rb');
ok = fseek(fp,0,'eof');
id = ftell(fp);
fclose (fp);

META.nRecs = id/2;
META.sec_of_recording = META.nRecs/META.sFreq_amp;
META.hrs_of_recording = META.sec_of_recording/60/60; %S anity check.

% current sampling interval
df = round(median(diff(POS(:,1))));
META.original_pos_sFreq = 1/(df/META.sFreq_amp);
META.sFreq_pos =META.sFreq_amp;

save('Meta_data','META');

disp(['Original Position Sampling Rate is ' num2str(META.original_pos_sFreq)])
x = 1:META.nRecs;
% x = 1:df:META.nRecs;
% Create a position file...
GOODPOSIX = ~isnan(POS(:,2)) & POS(:,2) > 10;
pos_fname = 'posx.dat';
fp = fopen(pos_fname,'wb');
fwrite(fp,int16(interp1(POS(GOODPOSIX,1),POS(GOODPOSIX,2),x)),'int16');
fclose(fp);
% Add these files to the list of data to import to smrx.
% pos_channels = max(META.RHD_CH):max(META.RHD_CH)+2;
nRec = length(META.RHD_CH);
META.sFreq_Ch(nRec+1) = META.sFreq_pos;
META.RHD_CH(nRec+1) = max(META.RHD_CH) + 1;
META.file_name{nRec+1} = pos_fname;
[~, META.Ch_Labs{nRec+1}] = fileparts(pos_fname);

%%
% x = 1:df:META.nRecs;
% Create a position file...
pos_fname = 'posy.dat';
fp = fopen(pos_fname,'wb');
fwrite(fp,int16(interp1(POS(GOODPOSIX,1),POS(GOODPOSIX,3),x)),'int16');
fclose(fp);
% Add these files to the list of data to import to smrx.
% pos_channels = max(META.RHD_CH):max(META.RHD_CH)+2;
nRec = length(META.RHD_CH);
META.sFreq_Ch(nRec+1) = META.sFreq_pos;
META.RHD_CH(nRec+1) = max(META.RHD_CH) + 1;
META.file_name{nRec+1} = pos_fname;
[~, META.Ch_Labs{nRec+1}] = fileparts(pos_fname);

% x = 1:df:META.nRecs;
% Create a position file...
GOODPOSIX = ~isnan(SPEED(:,2)) & SPEED(:,2) < 500;
pos_fname = 'speed.dat';
fp = fopen(pos_fname,'wb');
% Need to multiply by 1000 so that the 16 bit conversion does not kill all
% of the data.
fwrite(fp,int16(interp1(SPEED(GOODPOSIX,1),SPEED(GOODPOSIX,2)*1000,x)),'int16');
fclose(fp);
% Add these files to the list of data to import to smrx.
% pos_channels = max(META.RHD_CH):max(META.RHD_CH)+2;
nRec = length(META.RHD_CH);
META.sFreq_Ch(nRec+1) = META.sFreq_pos;
META.RHD_CH(nRec+1) = max(META.RHD_CH) + 1;
META.file_name{nRec+1} = pos_fname;
[~, META.Ch_Labs{nRec+1}] = fileparts(pos_fname);


disp('FILES TO COMBINE:')
META.Ch_Labs
%%
figure
subplot(2,1,1)
plot(POS(:,1),POS(:,2),'r')
hold on
plot(POS(:,1),POS(:,3),'m')
plot(POS(:,1),POS(:,4),'c')
plot(POS(:,1),POS(:,5),'b')
legend('Col 2','3','4','5')
ylabel('pixel')
xlabel('Rec ID'); title('Position data over time (in rec IDs');
subplot(2,1,2)
plot(SPEED(:,1),SPEED(:,2))
title('SPEED')
% Create the smrx file.
SPK2_IntanDat_to_SMR_Combine(['mouse' num2str(META.RAT_ID) '_' num2str(META.SESSION) '.smrx'],META);
%delete the temporary files.
delete('posx.dat')
delete('posy.dat')
delete('speed.dat')
if exist('time.data','file')
    delete('time.dat')
end


    

