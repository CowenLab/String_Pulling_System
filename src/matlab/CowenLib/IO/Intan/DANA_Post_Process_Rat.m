function INTAN_Post_Process_Acute(ch_trans_table)
% function INTAN_Post_Process_Acute(ch_trans_table)
%Post-process according to pinout and ntrode assignment in translation
%channel (rather than the other way around as with the behavioral system)
%This script is good for acute surgeries or one-off behavioral
%configurations, and as such just resamples LFP channels, assembles
%tetrodes and sorts spikes.

%Using this as a springboard, you can use "INTAN_Extract_Transitions" with
%the digital inputs to block out epochs and zero-out stimulation artifacts
%in a continous trace (or just have that digital input set up to trigger
%the fast-settle during data collection)
%
% INPUT:
%  e.g. INTAN_Post_Process_Acute('..\Channel_translation_table_Fertambieu_128_EIB_to_Amplipex_and_Intan.xlsx')
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Control variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
master_TicID = tic;
RUN_KKWIK = true;
HIGHPASS_FILTER = false; % NO NEED TO DO THIS! 
NOTCH_FILTER = false;
EXTRACT_SPIKES = false;

hpCutoff = 500;
%Filename of the event channel so we can find the epochs in the data files.
Intan_Event_Files = {'board-DIN-00.dat' 'board-DIN-01.dat' }; %Set this to the filename of the event channel. e.g. board-DIN-00.dat
Intan_Event_File_Meaningful_Names = {'StimStarts_EVT.mat' 'StimPulses_EVT.mat'};
%Note you can accomplish this during data collection by setting the stim
%channel to also trigger the fast settle.

%What we will resample tagged LFP channels at.
LFP_sFreq = 2000; %2000 is reasonable.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find important directories.
tmp = which('INTAN_Post_Process_Acute');
INTAN_src_dir = fileparts(tmp);
% move 2 dirs up.
tmp = fileparts(INTAN_src_dir);
Intan_root_dir = fileparts(tmp);
% Location of the batch file file spike sorting.
masterBatch = fullfile(Intan_root_dir, 'Batch2.txt');

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Set User-parameters, Get Filenames, Make Sure Environment is Kosher

if nargin == 0;
    ch_trans_table = '..\Channel_translation_table_ACC_Acute_Updated_08122014.xlsx'
   %% error('Please enter filename for the translation table reflecting the hardware configuration');
end

copyfile(masterBatch,pwd); %get the kkwik batch file

% [~, SessName, ~] = fileparts(pwd);  %Get unique session identifier from name.
header_file = 'info.rhd'; %default intan system header contains all amplifier metadata
f_info = dir(header_file);
if isempty(f_info)
    beep
    beep
    msgbox(['NO HEADER: You may be in the wrong directory'])
    return
end

% [p,data_root,e] = fileparts(header_file);

%This if statement does not function on Frieza!!!!!
      %%%%%Write another function for Frieza? Need to talk to Cowen/Rausher
      %%%%%WTR - 07102014

% % % % % % if (exist('amplifier.dat','file') || exist('auxiliary.dat','file') || exist('supply.dat','file'))
% % % % % %     beep
% % % % % %     beep
% % % % % %     error('Wrong Data Format. ("File Per Signal Type") Use/make a different post-processing script. Detected format is also compatible with Neuroscope.')
% % % % % %     msgbox(['Wrong Data Format. ("File Per Signal Type") Use/make a different post-processing script. Detected format is also compatible with Neuroscope.'])
% % % % % %     return
% % % % % % end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Import Metadata

% Import amplifier data header. This contains all the metadata and also
% provides a handy index of channel filenames, as they are formatted
% the same as the "Native Channel Name."
IF = INTAN_Read_RHD_file(header_file,1); %Loads the metadata in verbose mode

% Assign Time Vector File
tFile = 'time.dat'; % File contains Record ID count, not system time.

% Assign Sampling Frequencies
sFreq = IF.frequency_parameters.amplifier_sample_rate;
startRecID_Offset = findStartRecID(tFile,sFreq)-1; %Will equal zero unless the data files have been created with the "triggered recording" option.
if startRecID_Offset ~= 0
    msgbox('Be aware, triggered recordings were used so timestamps will start negative. Negative timestamps screw a lot of legacy code up.')
    % To make all of the analysis from this point on easier, the timestamps
    % should be converted so that they start at zero, NOT negative numbers.
end

RecID_to_uSec_conversion = 1e6/sFreq;
%LFP resampling frequency set at the top.
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%


%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Update Metadata from Translation Table
% Alter the imported header file data structure to reflect the hardware
% configuration described in the translation table.

TT = INTAN_Load_Channel_Trans_Table(ch_trans_table);
IF = INTAN_Update_Header_From_Trans_Table(IF,TT);

save('session_metadata','IF','TT','startRecID_Offset', 'RecID_to_uSec_conversion' );
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Get Event Times. NOTE: These times do not account for the offset. They
% assume that time starts at zero (which works better with all of our legacy code). 
for ii = 1:length(Intan_Event_Files)
    if ~isempty(Intan_Event_Files{ii}) && exist(Intan_Event_Files{ii},'file')
        UpTransitions_RecID = INTAN_Extract_Transitions(Intan_Event_Files{ii});
        DownTransitions_RecID = INTAN_Extract_Transitions(Intan_Event_Files{ii},1,1);
        UpTransitions_usec   = UpTransitions_RecID*RecID_to_uSec_conversion;
        DownTransitions_usec = DownTransitions_RecID*RecID_to_uSec_conversion;
        min(DownTransitions_usec)
        
        save(Intan_Event_File_Meaningful_Names{ii},'UpTransitions_RecID', 'DownTransitions_RecID','UpTransitions_usec','DownTransitions_usec');
    end
end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
% Find the intervals of the stim artifact and let's blank them out from the
% data.
%  Note: in theory, this could be done with the digital input file
%  associated with the stim, but I found that this file was not a clean set
%  of 0's and 1's. It confused me so I created this...
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%% SORRY - JP is editing this for DANA - MY B; 3 comments for what I'm commenting out
% % % Artifact_RecIDs = load('StimPulses_EVT.mat');
% % % time_before_msec = 3;
% % % time_after_msec = 3;
% % % 
% % % time_before_recids = IF.frequency_parameters.amplifier_sample_rate*time_before_msec/1000;
% % % time_after_recids =  IF.frequency_parameters.amplifier_sample_rate*time_before_msec/1000;
% % % 
% % % Artifact_Rejection_Intervals_StEd_RecIDs = zeros(length(Artifact_RecIDs.UpTransitions_RecID),2);
% % % Artifact_Rejection_Intervals_StEd_RecIDs(:,1) = Artifact_RecIDs.UpTransitions_RecID(:)-time_before_recids;
% % % Artifact_Rejection_Intervals_StEd_RecIDs(:,2) = Artifact_RecIDs.DownTransitions_RecID(:)+time_after_recids;
% % % nRecs_to_remove = sum(Artifact_Rejection_Intervals_StEd_RecIDs(:,2) - Artifact_Rejection_Intervals_StEd_RecIDs(:,1)) + Rows(Artifact_Rejection_Intervals_StEd_RecIDs); % need to add rows - 1:1 would mean you still rejected 1 record.
% Create a mask file of the same size as the dat files.
d = dir('amp-D-0*.dat');
o = ones(d(1).bytes/2,1,'int16');
% % % for iR = 1:Rows(Artifact_Rejection_Intervals_StEd_RecIDs)
% % %     o(Artifact_Rejection_Intervals_StEd_RecIDs(iR,1):Artifact_Rejection_Intervals_StEd_RecIDs(iR,2)) = 0;
% % % end
% Write the file
Artifact_mask_fname = 'Mask_out_these_recs.dat'; %leave this blank to transparently skip epoch cancellation. or set it equal to filename in Intan_Event_Files to use.
fp = fopen(Artifact_mask_fname,'w');
fwrite(fp,o,'int16');fclose(fp);
% % % save('Artifact_Rejection_Intervals_StEd_RecIDs','Artifact_Rejection_Intervals_StEd_RecIDs');

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Remove DC from amplifier channels and optionally cancel stimulus epoch to
% enable spike-sorting on continuous trace.
for i = 1:numel(IF.amplifier_channels)
    curFile = strcat('amp-',IF.amplifier_channels(i).native_channel_name,'.dat');
    if (exist(curFile,'file'));
        Remove_DC_and_Apply_Hardware_Mask(curFile,Artifact_mask_fname);
    end
end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
% % % if 0 % this is just for validation - that the artifact was actually removed.
% % %     D =  INTAN_Read_DAT_file(curFile);
% % %     figure
% % %     plot(D);
% % %     plot_markers_simple(Artifact_Rejection_Intervals_StEd_RecIDs(:,1),[],[],'g')
% % %     plot_markers_simple(Artifact_Rejection_Intervals_StEd_RecIDs(:,2),[],[],'r')
% % %     hold on
% % %     plot(standardize_range(double(o),[min(D) max(D)]),'c')
% % % end
%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Resample LFP channels and give them their own time vector.
% If Reference_Ch is specified, re-references them, too.
INTAN_Extract_LFP(IF,LFP_sFreq); % This also does not adjust for the offset - so let's not do this in the ntt files.
% Move LFPs to their own directory
if ~isempty(dir('*.datlfp'))
    if ~exist('LFP','dir')
        mkdir('LFP')
    end
    movefile('*.datlfp','LFP')
    movefile('time_LFP.dat','LFP')
    copyfile(header_file,'LFP')
end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Get Spikes using UltraMegaSort2000. This will create ntt files and will
% also save spikes in usec, not record IDs
% INTAN_Extract_Spikes(IF,sFreq,startRecID_Offset);
% 
% if HIGHPASS_FILTER
%     INTAN_Filter_Amplifier_Channels(IF,hpCutoff,NOTCH_FILTER);
% end

if EXTRACT_SPIKES
    INTAN_Extract_Spikes(IF,IF.frequency_parameters.amplifier_sample_rate,0); % do not put in the offset. Need to know how to fix this
end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Cluster Cut
% Run the bat file in situ. If hard drive space is a concern have it move
% the files like the AMPX script does.
if EXTRACT_SPIKES && RUN_KKWIK
    disp('Getting ready to KKwik!!!!111oneelevenpointninerecurringlimx->0sinx/x')
    %     addpath(genpath(fullfile(Home_dir,'MClustSE_v3.1_temp')));
    % READY TO KKWICK!!!
    RunClustBatch2('Batch2.txt')
end
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%

%vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv%
% Wrap-Up
total_time_sec = toc(master_TicID);
infoTime = dir(tFile);
hrs_of_data = infoTime.bytes/sFreq/4/60/60;
msgbox([ 'INTAN_Post_Process: Postprocessing took a total of ' num2str(total_time_sec/60/60) ' hrs to complete for ' num2str(hrs_of_data) ' hrs of recorded data.  ' pwd ' Wait while validating'])

% INTAN_Validate_Data2() % Generates plots

end %End of Post-Processing Function
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^%
%                             ::::'###########################################::::::#####:::::::::::::::#
%      ::############:::                                                                                '
%   :                                                                                                   #
%   :           #                                                                                       #
%   :      ## # # #                  #                                                                  #
%   :                               .#                                                                  #
%   :                               # #                                                                 #
%   :                               # #                                                                 #
%   :                               # #                                                                 #
%   :                               ' #                                                                 #
%   :       :                       : .                                                                 #
%   :                        .         .                                                                #
%   :                                  :                                                                #
%   :                                  #                                                                #
%   :                                  #                                                                #
%                                      #                                                                #
%          ##                      .   #                                                                #
%                                  .   #                                                                #
%                                  .   #                                                                #
%          .                       '   :                                                                #
%                                  #   :                                                                #
%    :                             '                                                                    #
%    .     ''.                     #    :                                                               #
%    :                             :    :                                                               #
%    :                         .   .    :                                                               #
%                                       :                                                               #
%   :                                   #                                                               #
%   :           #                       #                                                               #
%   :      ::##  '                      #                                                               #
%   :           :                       #                                                               #
%   :                                   #                                                               #
%   :                                   #                                                               #
%   :                             :     #                                                               #
%                                 '     #                                                               #
%                                 '     '                                                               #
%                                 #     :                                                               #
%                                 #     :                                                               #
%                                 #     .                                                               #
%                                 #      .                                                              #
%                                 #      :                                                              #
%          ::.                    :      :                                                              #
%    .                            .      '                                                              #
%                                        #                                                              #
%    .                           :       #                                                              #
%    :                           #       #                                                              #
%    :                           #       #                                                              #
%    :                           #       #                                                              #
%    :                           #       #                                                              #
%    :                           #       #                                                              #
%    :                          ::       :                                                              #
%    :                          #        ::                                                             #
%    :                          #         :                                                             #
%    :     ':.                 .#         #                                                             #
%    :                    :    #:         #                                                             #
%    :                   '## .##          #                                                             #
%    :#########################           #                                               :##############
%    :     .                ::            #                                    . .################:     #
%    :                                    ::                               .##############:.            #
%    :                                     #                           .###########':                   #
%    :                                     #                       ###########:                         #
%    :                                     ##                  ###########:                             #
%    :     `                               ;#`            ;##########+ `                                #
%    :                                      ##.     :::###########                                      #
%    #     .                                 ################:                                          '
%    #     .                                  ###########                                               #
%    #                                                                                                  #
%    #                                                                                                  #
%    :     .                                                                                            #
%    :     .                                                                                            #
%    :          #.'                                                                                     #
%    :     ': :.   #                                                                                    #
%    :          ' #                                                                                     #
%    :                                                      '##                                .##      #
%    :                ###                                  ,###.                               # :'     #
%    :                '  #                                 #   #                              #.  #     #
%    :               #   .:                                #   #.                             #   .:    #
%    :               #    #                               '`   :#                             '    #    #
%    :               .    .                               #     #                            #     #    #
%    :              '      '                              #     '                            #     .    #
%    :              #      #                             .#     .#                           #      :   #
%    :              :      :                             '       #                          .       #   #
%    :                      .                            #       #                          #       #   #
%    :                      #                            #       ':                         #       '   #
%    #                      '                            #        :                         #           #
%    :                                                  .         #                        .         :  #
%    #                       :                          #         #                        #         #  #
%    :               ::::::::##########:::::::::::::::::::::::::::::::::::::::::::                      #
%    ##'::::
