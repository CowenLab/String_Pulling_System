function [IMU, IMU_INFO] = INTAN_Extract_IMU(data_dir,IMU_data_file,StrobeRecIDs,SigRecIDs, IF)
% Adapted from analagous AMPX function--changes how files and metadata are
% discovered to be appropriate for the intan system.
% extract all of the IMU events from the current data directory.

output_sample_rate_hz = 40;

if nargin < 1
    data_dir = pwd;
end
if nargin < 2
    d = dir('rat*IMU*.log');
    if isempty(d)
        pwd
        disp('NO IMU LOG FILE FOUND')
        return
    end
    
    if length(d) > 1
        error('Too many IMU log files in this directory.')
    end
    IMU_data_file = d(1).name;
end

if nargin < 3
    StrobeRecIDs = [];
    SigRecIDs = [];
end
if nargin < 5
    IF = INTAN_Read_RHD_file();
end

if ~isempty(data_dir)
    p = pwd;
    cd (data_dir)
end

disp('Processing IMU events.')

if isempty(SigRecIDs)
    if exist('IMU_events_recID.mat','file')
        load IMU_events_recID.mat
    else
        IMU_strobe_Ch = findIntanBoardChannelsByName('IMU STROBE',IF,'digital in');
        IMU_sig_Ch = findIntanBoardChannelsByName('IMU SIG',IF,'digital in');
        StrobeRecIDs = INTAN_Extract_Transitions(IMU_strobe_Ch);
        SigRecIDs = INTAN_Extract_Transitions(IMU_sig_Ch);
        save('IMU_events_recID.mat', 'StrobeRecIDs','SigRecIDs')
    end
end
StrobeRecIDs = StrobeRecIDs - 6; % The strobe occurs just after the signal - strange. In the IMU code it should occur before? - need to look at this.
EventCodes = bin_times_by_intervals(SigRecIDs, StrobeRecIDs-3, StrobeRecIDs+3);
%Time_SyncCode = IMU_process_event_file([StrobeTimes(:)*RecID_to_uSec_conversion EventCodes(:)]);
if(exist('time.dat')
    startRecID_Offset = findStartRecID - 1;
else
    startRecID_Offset = 0; %Guess no offset if can't find the time file. This will only not be true if you have a started the recording on a trigger.
end
RecID_to_uSec_conversion = 1e6/IF.frequency_parameters.amplifier_sample_rate;
StrobeTimestamps_usec = (StrobeRecIDs(:)-startRecID_Offset)*RecID_to_uSec_conversion;
%save('Matlab_state.mat');
[IMU IMU_INFO] = IMU_sync_IMU_log_and_neural_timestamps(IMU_data_file, [StrobeTimestamps_usec(:) EventCodes(:)], output_sample_rate_hz);
save('IMU','IMU','IMU_INFO')

fld = fieldnames(IMU);
figure
for ii = 1:length(fld)
    subplot(length(fld),1,ii)
    plot(IMU.(fld{ii})(:,1)/1e6/60,IMU.(fld{ii})(:,2))
    hold on
    plot(IMU.(fld{ii})(:,1)/1e6/60,IMU.(fld{ii})(:,3),'r')
    plot(IMU.(fld{ii})(:,1)/1e6/60,IMU.(fld{ii})(:,4),'g')
    title(fld{ii})
    axis tight
end
xlabel('min')
saveas(gcf,'IMU','png')

if ~isempty(data_dir)
    cd (p)
end
toc