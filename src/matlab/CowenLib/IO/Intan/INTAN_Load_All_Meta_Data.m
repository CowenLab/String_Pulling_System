function INTAN = INTAN_Load_All_Meta_Data(ch_translation_table_file)
% Creates an Intan parameters file
% Very Similar to the AMPX parameters file but here channel variables are
% used to store the filename of a given digital channel.

% load in the meta file
header_file = 'info.rhd'; %default intan system header contains all amplifier metadata
f_info = dir(header_file);
if isempty(f_info)
    beep
    beep
    msgbox(['NO HEADER: You may be in the wrong directory'])
    return
end
INTAN.HEADER = INTAN_Read_RHD_file(header_file,1); %Loads the metadata in verbose mode
INTAN.CH_ASSIGNMENTS = INTAN_Load_Channel_Trans_Table(ch_translation_table_file);
INTAN.sFreq = INTAN.HEADER.frequency_parameters.amplifier_sample_rate;
INTAN.LFP_sFreq = 1000;
INTAN.Event_Ch = ''; % Which channel are the events being stored.
INTAN.IMU_strobe_Ch = '';
INTAN.IMU_sig_Ch = '';
INTAN.AVT_Camera_Video_Sync_Ch = 'board-DIN-04.dat';
INTAN.AVT_Camera_strobe_Ch = 'board-DIN-06.dat';
INTAN.AVT_Camera_sig_Ch = 'board-DIN-05.dat';
INTAN.Lick_sensor_Ch = '';
INTAN.Voltammetry_Sync_Channel = ''; 
end