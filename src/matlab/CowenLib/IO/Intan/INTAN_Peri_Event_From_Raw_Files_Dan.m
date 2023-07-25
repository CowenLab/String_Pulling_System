%INTAN_Peri_Event_From_Raw_Files()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A script to generate peri-event LFP and spike plots acquired from the
% Open Ephys Intan system. Developed to test optogenetic stimulation.
% 
% I would recommend that you create a new recording folder for each major
% experimental condition (e.g. a change in the depth of the electrode)
%
% Run this script in the directory containing all of the .dat files from the Intan
% or Open Epys box. It assumes that you chose to save each channel as an
% independent file. This has to be set in the Intan acquisition software.
% This code also assumes that Cowen's matlab 'Working' folder is in the
% matlab path. 
%
% Cowen 2015
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The following parameters can be edited by the average user to customize plots
% and specify plot windows. Parameters and code beyond this point can be
% edited, but make a backup if you are not sure what you are doing.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ca
clear
%whichamp = input('Which amplifier was the data collected on (A, B, C, D?)','s');
whichamp = 'B';
spkchan = input('Which channel do you want to analyse?(00-31)', 's');
str1 = 'amp-';
str2 = whichamp;
str3 = '-0';
str4 = spkchan;
str5 = '.dat'; 
fulstr = strcat(str1, str2, str3, str4, str5);
LFP_file   = fulstr; % first group was amp-A-009.dat remeber - INtan starts at 0, not 1
Spike_file = fulstr; % put in a file if you think that there are spikes on that channel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Event_code_file  = 'board-DIN-08.dat'; % Codes for event ID's
Laser_pulse_file = 'board-DIN-09.dat'; % the raw signal sent to the laser.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
USE_NOTCH = false;
LFP_sFreq = 100; % the downsampled LFP sampling frequency. If you want to see spikes, then make this near sFreq.
sec_before = 1;   % time before the peri-event response
sec_after = 1.5;  % time after the peri-event response
thresh_spk_std = 4.0; % the standard deviation to detect spikes.
%IF.amplifier_channels.native_channel_name
IF = INTAN_Read_RHD_file(); % meta data.
sFreq = IF.frequency_parameters.amplifier_sample_rate;
% IF.amplifier_channels(1).is_LFP = 1; % Set this as a channel to extract.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load the event times.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fp = fopen(Laser_pulse_file,'rb');
tmp = fread(fp,'int16');
fclose(fp);
d = [0 ;diff(tmp)]; % extract times as deflections.
LaserUpRecs = find(d>0);
LaserDownRecs = find(d<0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert to units of time. usec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LaserUpUsec = (LaserUpRecs/(sFreq/1e6));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fp = fopen(Event_code_file,'rb');
tmp = fread(fp,'int16');
fclose(fp);
% Determine the event times.
d = [0 ;diff(tmp)];
% Convert to units of time.
EventUpRecs = find(d>0);
EventDownRecs = find(d<0);
EventUpUsec = (EventUpRecs/(sFreq/1e6));
%% Extract codes from these event transitions.
EVT = Events_from_transition_times(EventUpUsec, 515, 1000);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Extract LFP data and downsample.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fp = fopen(LFP_file,'rb');
LFP = fread(fp,'int16');
fclose(fp);
LFP = LFP - mean(LFP); % get rid of DC offset if there is any.
if USE_NOTCH
% Apply a notch filter.
LFP = Notch_filter(LFP,sFreq);
end
LFP = resample(LFP,LFP_sFreq,sFreq); % gets rid of aliasing.
LFP_usec = (1:length(LFP))/(LFP_sFreq/1e6);
LFP_usec = LFP_usec(:);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot raw event times and the data..
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(1)
clf
plot(LFP_usec/1e6,LFP,'b')
axis tight
hold on
h = plot_markers(EVT(:,1)/1e6, 2, EVT(:,2));
xlabel('s');title('Event times');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For all unique events that occur more than 4 times, create an
% event-triggered average.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
unique_events = unique(EVT(:,2));
for iEvent = 1:length(unique_events)
    IX = EVT(:,2) == unique_events(iEvent);
    if sum(IX) > 4
        T_usec = EVT(IX,1);
        %         figure
        %         PETH_EEG_simple([LFP_usec LFP], T_usec, sec_before*LFP_sFreq, sec_after*LFP_sFreq, LFP_sFreq);
        %         title(num2str(unique_events(iEvent)))
        figure
        PETH_EEG_spect_simple([LFP_usec LFP], T_usec, sec_before*LFP_sFreq, sec_after*LFP_sFreq, LFP_sFreq);
        title(['Event ' num2str(unique_events(iEvent))])
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Stack the peri-event plots.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(10)
clf
npts_before = sec_before*LFP_sFreq;
npts_after = sec_after*LFP_sFreq;
sd = std(LFP);
for ii = 1:min([Rows(EVT) 50])
   ix = find(LFP_usec > EVT(ii,1),1,'first');
   rng_ix = (ix-npts_before):(ix+npts_after);
   x = (LFP_usec(rng_ix)-LFP_usec(ix))/1000;
%    subplot(5,4,ii);
   plot( x, LFP(rng_ix) + 2*sd*ii,'k')
   hold on
   axis tight
   if ii==1
       xlabel('ms')
   end
   text(x(1)-100, 2*sd*ii,num2str(EVT(ii,2)),'Color','r')
end
set(gca,'YTickLabel','')
plot_vert_line_at_zero;
pubify_figure_axis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% If there is a spike file, filter it for spikes and go for it (crudly).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(Spike_file)
    fp = fopen(Spike_file,'rb');
    LFPspk = fread(fp,'int16');
    fclose(fp);
    LFPspk = Filter_for_spikes(LFPspk,sFreq);
    LFPspkusec = (1:length(LFPspk))/(sFreq/1e6);
    LFPspkusec = LFPspkusec(:);
    spike_threshold = -thresh_spk_std*std(LFPspk);
    IX = LFPspk < spike_threshold;
    d = diff([0;IX]);
    spk_ix = find(d > 0);
    spk_usec = spk_ix/(sFreq/1e6);
    if length(spk_ix)> 5
        for iEvent = 1:length(unique_events)
            IX = EVT(:,2) == unique_events(iEvent);
            if sum(IX) > 4
                T_usec = EVT(IX,1);
                %         figure
                %         PETH_EEG_simple([LFP_usec LFP], T_usec, sec_before*LFP_sFreq, sec_after*LFP_sFreq, LFP_sFreq);
                %         title(num2str(unique_events(iEvent)))
                figure
                PETH_raster_dan(spk_usec/100, T_usec/100, 10, sec_before*1000,sec_after*1500);
                title(['Event ' num2str(unique_events(iEvent))])
                figure
                M = PETH_EEG_simple([LFPspkusec LFPspk], T_usec, sec_before*sFreq, sec_after*sFreq, sFreq);
%                 M = Z_scores(M')';
               plot_LFP(M',sFreq,460)
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extra notes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FYI: the time.dat file just counts the records - probably ignore. signed
% integer 32. the vdd file are the voltage levels for the board. 
% Aux 1,2,3 are the accelerometer boards.
% INTAN_Validate_LFP - %plot LFP aligned on events.
% Other things...
% This will take the RHD and trans table and integrate them
% TT = INTAN_Load_Channel_Trans_Table(ch_trans_table);
% IF = INTAN_Update_Header_From_Trans_Table(IF,TT);
% META = INTAN_Update_Header_From_Trans_Table(R
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
