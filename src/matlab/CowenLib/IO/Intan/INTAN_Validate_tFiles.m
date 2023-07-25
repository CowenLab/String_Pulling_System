function INTAN_Validate_tFiles()
% Create PETHs and other plots from the found files in this directory to
% determine if the data collected makes any sense.
%% Cowen 2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Control what's plotted.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PLOT_LFP = false;
PLOT_EVENT_VS_EVNT = false;
PLOT_PETH_CUT_SPIKES = true;
PLOT_MUA = false;
SAVE_FIGURES = true;
event_type = 'UpTransitions_usec';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find files:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
event_files = find_files('*_EVT.mat');
% spike_waveform_files = {'spk_D3-4V_140605_160506_nCh_4_Chnl_21_22_23_24.ntt' 'spk_D3-4V_140605_160506_nCh_4_Chnl_9_10_11_12.ntt'};
spike_waveform_files = find_files('*.ntt');
% LFP_files = {'./LFP/LFP_Ch_31_Skip_15.datlfp' './LFP/LFP_Ch_27_Skip_15.datlfp'};
LFP_files = find_files('./LFP/*.datlfp');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the meta data.
load('session_metadata.mat','IF','RecID_to_uSec_conversion');
% Load in the times of the events.
ET = cell(length(event_files),1);
for iEvt = 1:length(event_files)
    load(event_files{iEvt})
    ET{iEvt}.UpTransitions_usec = UpTransitions_usec;
    ET{iEvt}.DownTransitions_usec = DownTransitions_usec;
    fprintf('Event %d: Est event duration of %2.4f minutess\n',iEvt, (ET{1}.(event_type)(end) - ET{1}.(event_type)(1))/1e6/60)
end
% Load MUA (everything that crosses threshold)
t_usec  = cell(length(spike_waveform_files),1);
first_spike = zeros(length(spike_waveform_files),1);
for iWV = 1:length(spike_waveform_files)
    t_usec{iWV} = Nlx2MatSpike(spike_waveform_files{iWV}, [1 0 0 0 0 ], 0, 1, 0 );
    first_spike(iWV) = t_usec{iWV}(1);
end

fprintf('Est recording duration of %2.4f minutess\n',(t_usec{1}(end) - t_usec{1}(1))/1e6/60)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Create PETHs of the spike times.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if SAVE_FIGURES
    if ~exist('Validation_Figures','dir')
        mkdir 'Validation_Figures';
    end
end
% function [M, x_axis, A_msec ] = PETH_raster(spike_times_ts,alignments_ts,bin_and_inc_size_msec,time_before_msec,time_after_msec,option)
time_before_msec = 2000;
time_after_msec = 2000;
bin_and_inc_size_msec = 15;

if PLOT_MUA
    count = 1;
    for iWV = 1:length( t_usec)
        for iEvt = 2:2 % length(ET)
            figure(count + 100)
            clf
            PETH_raster(t_usec{iWV}/100, ET{iEvt}.(event_type)/100,bin_and_inc_size_msec,time_before_msec,time_after_msec )
            title([event_files{iEvt} ' ' spike_waveform_files{iWV}])
            if SAVE_FIGURES
                saveas(gcf,['.\Validation_Figures\PETH_' event_type '_' num2str(count)],'png')
                close
            end
            count = count + 1;
        end
    end
end

if PLOT_PETH_CUT_SPIKES
    d = dir('*.t');
    if ~isempty(d)
        count = 1;

        for iFile = 1:length(d)
            t = LoadSpikes({d(iFile).name});
            t_usec = Data(t{1}) * 100;
            for iEvt = 2:2 % length(ET)
                figure(count + 300)
                clf
                PETH_raster(t_usec/100, ET{iEvt}.(event_type)/100,bin_and_inc_size_msec,time_before_msec,time_after_msec )
                title([event_files{iEvt} ' ' d(iFile).name])
                if SAVE_FIGURES
                    saveas(gcf,['.\Validation_Figures\PETH_from_t_file_' event_type '_' num2str(count)],'png')
                    %close
                end
                count = count + 1;
            end
        end
    else
        disp('NO .t FILES FOUND')
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Create STAs of the LFP signal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
count = 1;
LFP_t_sec = INTAN_Load_Time('./LFP/time_lfp.dat');
sFreq = 1/median(diff(LFP_t_sec));
% Design a filter with a Q-factor of Q=35 to remove a 60 Hz tone from
% system running at 300 Hz.
Wo = 60/(sFreq/2);  BW = Wo/35;
f_notch = 60;
[a,b] = INTAN_notch_filter(sFreq, f_notch);
        
LFP_t_usec = LFP_t_sec*1e6;
nTimeStamps = length(LFP_t_usec);
samples_before = round(sFreq)*1; % multiply by the seconds you want to show
samples_after = round(sFreq)*1;
if PLOT_LFP
    for iLFP = 1:length( LFP_files)
        % Load the LFP data.
        fid = fopen(LFP_files{iLFP}, 'r');
        lfp = fread(fid, inf, 'int16');
        fclose(fid);
        
        % Filter - notch
        
        lfp = filter(b,a,lfp);
        
        
        nRecs = min([length(lfp) nTimeStamps]); % this accounts for the strange thing in which the ts file is not the same size as the data.
        % notch filter
        % get rid of some artifacts.
        BADIX = abs(lfp) > 2400; % arbitrary but it works to get rid of artifact.
        lfp(BADIX) = nan;

        
        for iEvt = 2:2 %length(ET)
            figure(count + 200)
            clf
            PETH_EEG_simple([LFP_t_usec(1:nRecs)' lfp(1:nRecs)], ET{iEvt}.(event_type),samples_before,samples_after,sFreq);
            
            title([event_files{iEvt} ' ' spike_waveform_files{iWV}])
            if SAVE_FIGURES
                saveas(gcf,['.\Validation_Figures\LFP_ETA_' event_type '_' num2str(count)],'png')
                close
            end
            count = count + 1;

        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Just for thoroughness, let's make a PETH of the events against each
% other.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time_before_msec = 6000;
time_after_msec = 6000;
bin_and_inc_size_msec = 4;
if length(ET) > 1 && PLOT_EVENT_VS_EVNT
    for iEvt = 2:2 %length(ET)
        figure(count + 300)
        clf
        PETH_raster(ET{iEvt}.(event_type)/100, ET{iEvt-1}.(event_type)/100,bin_and_inc_size_msec,time_before_msec,time_after_msec );
        title([event_files{iEvt-1} ' ' event_files{iEvt}])
        if SAVE_FIGURES
            saveas(gcf,['.\Validation_Figures\EVT_vs_EVT_' event_type '_' num2str(iEvt)],'png')
            close
        end
    end
end
