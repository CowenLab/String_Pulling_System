
ca;

mdir = pwd;

if ~exist('mydir','var')
    mydir = uigetdir(mdir,'Where''s the dir bro?');
    cd(mydir);  
    
elseif exist('mydir','var')
    if isequal(mydir, mdir)

    else 
        mydir = uigetdir(mdir,'Where''s the dir bro?');
        cd(mydir);   
    end
end

clearvars -except mydir;
%%

Event_code_file  = 'board-DIN-01.dat'; % Codes for event ID's
Laser_pulse_file = 'board-DIN-00.dat'; % the raw signal sent to the laser.

% USE_NOTCH = false;
sec_before = 1;   % time before the peri-event response
sec_after = 1.5;  % time after the peri-event response
thresh_spk_std = 4.0; % the standard deviation to detect spikes.
%IF.amplifier_channels.native_channel_name
IF = INTAN_Read_RHD_file(); % meta data.
sFreq = IF.frequency_parameters.amplifier_sample_rate;
%%
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

[above_times,below_times] = find_intervals(tmp,.1,0,.1,60);

% % Determine the event times.
d = [0 ;diff(tmp)];
% % Convert to units of time.
EventUpRecs = find(d>0);
EventDownRecs = find(d<0);
EventUpUsec = (EventUpRecs/(sFreq/1e6));

bit_interval = 480; %48ms
within_rec_interval = 2000; %2seconds

% Extract codes from these event transitions.
EVT = Events_from_transition_times(EventUpUsec, bit_interval, within_rec_interval); %%%dtoo%%%%this was 10000...I changed it to 20000
% EVT= EventUpRecs;
%%
% evt_times = tmp >= 1;
% ups = diff (evt_times);
% event_times = find(ups > 0);
% event_times_s = event_times/20000; %turns this into s
% event_times_tenthms = event_times_s*10000;
%%
% unique_events = unique(EVT(:,2));
% spykfil = 'amp-B-013.dat';
% fp = fopen(spykfil, 'rb');


files = dir('amp*_CAR.dat');
% for file = files';
for iFile = 1:length(files);
    
    fp = fopen(files(iFile).name, 'rb');
    
    LFPspk = fread(fp,'int16');
    fclose(fp);
    LFPspk = Filter_for_spikes(LFPspk,sFreq);
    LFPspkusec = (1:length(LFPspk))/(sFreq/1e6);
    %     LFPspkusec = LFPspkusec(:);
    spike_threshold = -thresh_spk_std*std(LFPspk);
    IX = LFPspk < spike_threshold;
    d = diff([0;IX]);
    spk_ix = find(d > 0);
    spk_usec = spk_ix/(sFreq/1e6);
    figure
%     if length(spk_ix)> 5
%         for iEvent = 1:length(unique_events)
%             IX = EVT(:,2) == unique_events(iEvent);
%             if sum(IX) > 4
% 
%                 T_usec = EVT(IX,1);


                T_usec = EventUpUsec(find(ix>0):end);
                ix = diff(diff(EventUpUsec)>10000);


                PETH_raster(spk_usec/100,T_usec/100, 10, sec_before*1000,sec_after*1000);
                nombre = files(iFile).name;
                [pathstr,name,ext] = fileparts(pwd);
                nombredos = name(1:end-14);
                %                 tits = strcat('nombre';'nombredos');
                h = title({nombre;nombredos});
                P = get(h,'Position');
                set(h,'Position', [P(1) P(2)+.7 P(3)]);
%             end
%         end
%     end
end
    

ix = diff(diff(EventUpUsec)>600)
EVT = EventUpUsec(find(ix>0):end)

% % % 
% % % for iFile = 1:length(files);
% % %     
% % %     fp = fopen(file.name, 'rb');
% % %     
% % %     LFPspk = fread(fp,'int16');
% % %     fclose(fp);
% % %     LFPspk = Filter_for_spikes(LFPspk,sFreq);
% % %     LFPspkusec = (1:length(LFPspk))/(sFreq/1e6);
% % %     %     LFPspkusec = LFPspkusec(:);
% % %     spike_threshold = -thresh_spk_std*std(LFPspk);
% % %     IX = LFPspk < spike_threshold;
% % %     d = diff([0;IX]);
% % %     spk_ix = find(d > 0);
% % %     spk_usec = spk_ix/(sFreq/1e6);
% % %     if length(spk_ix)> 5
% % %         for iEvent = 1:length(unique_events)
% % %             IX = EVT(:,2) == unique_events(iEvent);
% % %             if sum(IX) > 4
% % %                 T_usec = EVT(IX,1);
% % %                 
% % %                 figure
% % %                 PETH_raster(spk_usec/100,T_usec/100, 10, sec_before*1000,sec_after*1000);
% % %                 nombre = file.name;
% % %                 [pathstr,name,ext] = fileparts(pwd);
% % %                 nombredos = name(1:end-14);
% % %                 %                 tits = strcat('nombre';'nombredos');
% % %                 h = title({nombre;nombredos});
% % %                 P = get(h,'Position');
% % %                 set(h,'Position', [P(1) P(2)+.7 P(3)]);
% % %             end
% % %         end
% % %     end
% % % end
% % %     


