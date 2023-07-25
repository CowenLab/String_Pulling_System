function INTAN_Post_Process_Rm_334_fix_DIN(DATA_DIR, DIN_ZIP_DIR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fixes a problem with the EVT file where the DIN data for the treadmill
% did not extract the pulse duration. Now the pulse start and end of all pulses
% is returned.
% e.g.
% DATA_DIR = 'C:\Users\Stephen Cowen\Box\Cowen Laboratory\Data\LID_Ketamine_Single_Unit_R56\Rat320\03';
% DIN_ZIP_DIR = 'Z:\Data\LID_Ketamine_Single_Unit_R56\Data\Rat320\03';
% DIN_ZIP_DIR = 'H:\';
% Cowen 2020.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Variables
DINfile.pos_strobe_ID = 'board-DIN-10.dat'; %9
DINfile.pos_unique_code_ID = 'board-DIN-09.dat'; %8
DINfile.pos_frame_ID = 'board-DIN-11.dat'; %10
DINfile.front_camera_frame_ID = 'board-DIN-15.dat'; % for the front facing camera.
DINfile.rotary_encoder_ID = 'board-DIN-12.dat'; % rotary encoder
DINfile.treadmill_ID = 'board-DIN-14.dat'; % rotary encoder
event_out_file = fullfile(DATA_DIR,'EVT.mat');
backup_event_file = fullfile(DATA_DIR,'EVTold2.mat');
% Backup old EVT file.
copyfile(event_out_file,backup_event_file);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load and save the meta data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
IF = INTAN_Read_RHD_file(fullfile(DATA_DIR,'info.rhd')); %IF will contain meta data on the Intan session
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Process event data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ff = find_files(fullfile(DIN_ZIP_DIR,'*DIN*.dat'));
if isempty(ff)
    disp('No DIN files, assuming a zip file here.')
    d = dir(fullfile(DIN_ZIP_DIR,'DIN_FILES.zip'));
    if isempty(d)
        error('No DIN files.')
    end
    unzip(fullfile(DIN_ZIP_DIR,'DIN_FILES.zip'),DIN_ZIP_DIR);
end

fields = fieldnames(DINfile);
% if ~exist(event_out_file,'file')
for iF = 1:length(fields)
    fname = fullfile(DIN_ZIP_DIR, DINfile.(fields{iF}));
    %         fname = DINfile.(fields{iF});
    if exist(fname,'file')
        EVT.(fields{iF}) = INTAN_Extract_Times_From_DIN( fname );
        if ~contains(fields{iF},'treadmill')
            EVT.(fields{iF}) = EVT.(fields{iF})(:,1);
        end
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
if exist(fullfile(DIN_ZIP_DIR,'DIN_FILES.zip'),'file')
    delete(fullfile(DIN_ZIP_DIR,'*DIN*.dat'))
else
    zip(fullfile(DIN_ZIP_DIR, 'DIN_FILES'),ff);
    delete(fullfile(DIN_ZIP_DIR,'*DIN*.dat'))
end
