function INTAN_Validate_Data_LFP(LFP_Time_Multiplier,SAVE_PATH)
% Create PETHs and other plots from the found files in this directory to
% determine if the data collected makes any sense.
%% Cowen 2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Control what's plotted.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PLOT_LFP = true;
PLOT_EVENT_VS_EVNT = true;
PLOT_PETHS = false;
PLOT_PETH_CUT_SPIKES = false;
PLOT_MUA = true;
PMTM = true;
MorletWavelet = true;
SAVE_FIGURES = true;
event_type = 'UpTransitions_usec';

if nargin == 0;
    LFP_Time_Multiplier = 1.0; %%Num of seconds before/after stimulus in LFP/PETH Files
    SAVE_PATH = '1.0sec';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Create STAs of the LFP signal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
count = 1;
fig = 500; %% for the MortletWavelet fig #
LFP_t_sec = INTAN_Load_Time('./LFP/time_lfp.dat');
sFreq = 1/median(diff(LFP_t_sec));
% Design a filter with a Q-factor of Q=35 to remove a 60 Hz tone from
% system running at 300 Hz.
Wo = 60/(sFreq/2);  BW = Wo/35;
f_notch = 60;
[a,b] = INTAN_notch_filter(sFreq, f_notch);
        
LFP_t_usec = LFP_t_sec*1e6;
nTimeStamps = length(LFP_t_usec);
samples_before = round(sFreq)*LFP_Time_Multiplier; % multiply by the seconds you want to show
samples_after = round(sFreq)*LFP_Time_Multiplier; % LFP_Time_Multiplier defined above
if PLOT_LFP
    for iLFP = 1:length(LFP_files)
        % Load the LFP data.
        fid = fopen(LFP_files{iLFP}, 'r');
        lfp = fread(fid, inf, 'int16');
        fclose(fid);
        
        % Filter - notch
        
        lfp = filter(b,a,lfp);
        
        nRecs = min([length(lfp) nTimeStamps]); % this accounts for the strange thing in which the ts file is not the same size as the data.
        % notch filter
        % get rid of some artifacts.
%         BADIX = abs(lfp) > 2400; % arbitrary but it works to get rid of artifact.
%         lfp(BADIX) = nan;
           
        for iEvt = length(event_files) %length(ET)
            figure(count + 200)
            clf
            PETH_EEG_simple([LFP_t_usec(1:nRecs)' lfp(1:nRecs)], ET{iEvt}.(event_type),samples_before,samples_after,sFreq);
             
            title([event_files{iEvt} ' ' spike_waveform_files{iWV}])
            if SAVE_FIGURES
                saveas(gcf,['.\Validation_Figures\' num2str(SAVE_PATH) '\LFP_ETA_' event_type '_' num2str(count)],'png')
                close
            end
            count = count + 1;
            
                open 'PETH_EEG_Workspace.mat';
                lfp_w = ['PETH_W' num2str(iLFP)];
                PETH_W = ans;
                save(['.\PETH_W_Files_' num2str(SAVE_PATH) '\' num2str(lfp_w)],'PETH_W');
        end 
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%PMTM and Morlet Wavelet Scripts
%%Run using PETH_W files created from last LFP Analysis

pethfiles = find_files(['PETH_W_Files_' num2str(SAVE_PATH) '\PETH_W*.mat']);

for iPeth = 1:length(pethfiles)
    seshfile = load(pethfiles{iPeth}); %loads the file
    
    %%Run PMTM Script
    if PMTM
        INTAN_Spectral_Analysis(seshfile,sFreq,iPeth,SAVE_PATH)
    end

    %% Run Morlet Wavelet Script
    if MorletWavelet
        INTAN_Wavelet(seshfile,sFreq,samples_before,samples_after,iPeth,SAVE_PATH)
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Just for thoroughness, let's make a PETH of the events against each
% other.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time_before_msec = 2000;
time_after_msec = 2000;
bin_and_inc_size_msec = 4;
if length(ET) > 1 && PLOT_EVENT_VS_EVNT
    for iEvt = 2:2 %length(ET)
        figure(count + 300)
        clf
        PETH_raster(ET{iEvt}.(event_type)/100, ET{iEvt-1}.(event_type)/100,bin_and_inc_size_msec,time_before_msec,time_after_msec );
        title([event_files{iEvt-1} ' ' event_files{iEvt}])
        if SAVE_FIGURES
            saveas(gcf,['.\Validation_Figures\' num2str(SAVE_PATH) '\EVT_vs_EVT_' event_type '_' num2str(iEvt)],'png')
            close
        end
    end
end
