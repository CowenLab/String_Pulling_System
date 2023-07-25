function [POS, POSrecids] = INTAN_Extract_POS(INTAN)
%takes the AVT_Process_Tracking_Log output and the Intan metadata and turns
%it into POS.mat outputs intercompatible with the AMPX ones. Handles all
%alignment stuff including translating elapsed time (zero at first frame)
%into recording elapsed time (zero at start of recording)

%Will work standalone just fine just run it in the same directory as the
%info.rhd file, the listed digital channel files for sync, strobe, and sig,
%and the .pos file from the AVT camera.

if nargin < 1
    try
        load('INTAN.mat');
    catch
        %disp('No unified meta file detected. Attempting with Default Values');
        try
            INTAN.HEADER = INTAN_Read_RHD_file();
        catch
            disp('No info.rhd file. aborting');
            POS = [];
            POSRecids = [];
            return
        end
        INTAN.AVT_Camera_Video_Sync_Ch = 'board-DIN-04.dat';
        INTAN.AVT_Camera_strobe_Ch = 'board-DIN-06.dat';
        INTAN.AVT_Camera_sig_Ch = 'board-DIN-05.dat';
    end
end

sFreq = INTAN.HEADER.frequency_parameters.amplifier_sample_rate;
recid_to_msec = sFreq/1E3;


d = dir( fullfile('*.pos'));
if length(d) > 1
    error('too many position files. There can be only one.')
elseif isempty(d)
    error('no pos file.')
end
avt_file = d.name;

avtPOS = AVT_Process_Tracking_Log(avt_file);
if ~isfield(avtPOS,'ElapsedTime')
    disp('Error: File corrupt or contains no data');
    return
end
fileinfo = dir(INTAN.AVT_Camera_Video_Sync_Ch);
nrecs = fileinfo.bytes/2;

sync_recID = INTAN_Extract_Transitions(INTAN.AVT_Camera_Video_Sync_Ch);
% alignment
strobe_recID = INTAN_Extract_Transitions(INTAN.AVT_Camera_strobe_Ch); %sequence of strobes for 16-bit serial word that increments every 100 frames.
sig_recID = INTAN_Extract_Transitions(INTAN.AVT_Camera_sig_Ch); % sequence of bits for strobed 16-bit serial word
syncbits = bin_times_by_intervals(sig_recID, strobe_recID-3, strobe_recID+3)'; %sequence of 0s and 1s relaying whether a sig record matches the strobe.
wordstarts = [];
words = [];
wordvals = [];

for i = 1:length(strobe_recID)
    word = find((strobe_recID > strobe_recID(i)-200*recid_to_msec) & (strobe_recID < strobe_recID(i)+200*recid_to_msec)); %grab all the transitions in a 400ms window around the focal record
    if length(word) == 16
        wordstarts = unique([wordstarts min(strobe_recID(word))]); %if there is a whole word, add the start so we can line the words up with sync_recID later.
        words = unique([words;syncbits(word)],'Rows','Stable');
    end
end
wordvals = bin2dec(num2str(fliplr(words)))*100'; %multiply by 100 b/c the frame reporter counter only increments every 100 frames.
alignment = find(histc(wordstarts,sync_recID)); 
start_offset = wordvals(1)-alignment(1)+1; %compare index of frame syncs with value of corresponding words--if the same, we are aligned and start at start (+1).
end_offset = min(length(sync_recID)+start_offset-1,length(avtPOS.ElapsedTime(start_offset:end))+start_offset-1); %now that we know the start our end options are "amp ended before camera or camera ended before amp"


POS = zeros(length(avtPOS.ElapsedTime(start_offset:end_offset)),7);
POSrecids = sync_recID(1:length(POS));
POS(:,1) = sync_recID(1:length(POS)) * recid_to_msec; % use recording channel sync times for timestamps -- we won't use the less accurate elapsed time value from the camera.
% (note that throughout this file I've been using "ElapsedTime" as our index in the .pos file of how many frames were recorded even if we don't use the values)

%blue
if isfield(avtPOS,'Blue')
    avtPOS.Blue(isnan(avtPOS.Blue(:,start_offset:end_offset,:))) = -1; %code any frames where the camera couldn't get a mark or where the computer missed the frame.
    POS(:,2:3) = avtPOS.Blue(:,start_offset:end_offset,:)';
else
    POS(:,2:3) = -1;
end
%green
if isfield(avtPOS,'Green')
    avtPOS.Green(isnan(avtPOS.Green(:,start_offset:end_offset,:))) = -1;
    POS(:,4:5) = avtPOS.Green(:,start_offset:end_offset,:)';
else
    POS(:,4:5) = -1;
end
%red
if isfield(avtPOS,'Red')
    avtPOS.Red(isnan(avtPOS.Red(:,start_offset:end_offset,:))) = -1;
    POS(:,6:7) = avtPOS.Red(:,start_offset:end_offset,:)';
else
    POS(:,6:7) = -1;
end

end