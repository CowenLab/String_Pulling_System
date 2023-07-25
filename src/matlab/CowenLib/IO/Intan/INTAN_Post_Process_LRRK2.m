function INTAN_Post_Process_LRRK2(ch_trans_table)
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
hpCutoff = 250;
%Filename of the event channel so we can find the epochs in the data files.
% Intan_Event_Files = {'board-DIN-00.dat' 'board-DIN-01.dat' }; %Set this to the filename of the event channel. e.g. board-DIN-00.dat
% Intan_Event_File_Meaningful_Names = {'StimStarts_EVT.mat' 'StimPulses_EVT.mat'};
%Note you can accomplish this during data collection by setting the stim
%channel to also trigger the fast settle.

%What we will resample tagged LFP channels at.
LFP_sFreq = 2e3; %2000 is reasonable.

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
