function [status] = INTAN_Real_Time_Read_and_Display_DH_no_volt(dirname,recs_back,channels,DIN)
% function [status] = INTAN_Real_Time_Read_and_Display(dirname,channels,recs_back)
%
% Plot the most recent group of recs on the intan system. Plot it
% you could also output this chunk (D) to a smrx file for viewing in spike
% 2.
% Cowen.
ca;
plotwave = 1;%set thica
%The T-numbers below are tetrodes. These can be used in the nargin
%statement below in lieu of writing in channels. 
T1 = [0 1 14 15];T2 = [2 3 12 13];T3 = [4 5 11 10];T4 = [6 7 8 9];
T5 = [16 17 30 31];T6 = [18 19 28 29];T7 = [20 21 26 27];T8 = [22 23 24 25];

% RHD = INTAN_Read_RHD_file;
% sFreq = RHD.frequency_parameters.amplifier_sample_rate;

RHD.bit_to_uvolt_conversion = .195;
sFreq = 30000;
warning('Bit to uV conversion and sampling frequency are hard-coded to 0.195 and 30000')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
trode = [0:31];%you can also type channels here but be sure to type the actual channel number (e.g., 0:31)
amp = 'B'; % change this to the desired port
Spike_Threshold = 55; %thrshold for spikes in uV
secs_back = 60; %number of seconds from end of file to be analyzed
noise_slicer = 200; %Set this to a desired voltage threshold to remove high amplitude noise
time_before = 1;%time in milliseconds to plot before the triggered spike
time_after = 2;%time in milliseconds to plot after the triggered spike
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
prewave = time_before*30;%convert time before and after wave trigger to msec
postwave = time_after*30;
thresh = Spike_Threshold/RHD.bit_to_uvolt_conversion;
chop = noise_slicer/RHD.bit_to_uvolt_conversion;


if nargin < 4
    DIN = 'board-DIN-04.dat'; % 
end
if nargin < 3
        channels = trode; % change this number to change which tetrode to look at
%     channels = 1;
end
if nargin < 2
    recs_back = sFreq*secs_back; % number of seconds to plot
end
if nargin < 1
    dirname = uigetdir(pwd,'Where is the directory with the data?'); % 
end
cd(dirname);

fclose all
str = ['amp-',amp,'-'];

dname = fullfile(dirname,DIN);
dp = fopen(dname,'rb');
status = fseek(dp, 0, 'eof');
end_rec = ftell(dp);
end_rec = floor(end_rec/2)*2; % make sure we end on a full rec as there are 2 bytes per record.

start_rec = end_rec - 2*recs_back;
nrecs = end_rec - start_rec;
Dn = zeros(nrecs/2,1);


loc = fseek(dp, start_rec ,'bof');
DIN_evts = fread(dp, nrecs/2, 'int16');
fclose(dp);


fname = fullfile(dirname,sprintf([str '%03d.dat'],channels(1)));
fp = fopen(fname,'rb');
status = fseek(fp, 0, 'eof');
end_rec = ftell(fp);
end_rec = floor(end_rec/2)*2; % make sure we end on a full rec as there are 2 bytes per record.

start_rec = end_rec - 2*recs_back;

nrecs = end_rec - start_rec;
fclose(fp);
D = zeros(nrecs/2,length(channels));

for iCh = 1:length(channels)
    wave = [];
    fname = fullfile(dirname,sprintf([str '%03d.dat'],channels(iCh)));
    fp = fopen(fname,'rb');
    loc = fseek(fp, start_rec ,'bof');
    LFP = fread(fp, nrecs/2, 'int16');
    %     [naLFP] = DANA_Remove_artifact_filt_for_spikes(LFP,DIN_evts);
    naLFP = Filter_for_spikes(LFP,sFreq);
    ab = length(find(naLFP>(chop)));
    be = length(find(naLFP<(-1*chop )));
    recs_removed = ab + be;
    disp([num2str(recs_removed),' data points were counted as noise and removed']);
    naLFP(naLFP >(chop))= 0;
    naLFP(naLFP <(-1*chop))= 0;
    D(:,iCh) = naLFP;
    st = Spikes_From_Threshold(naLFP,thresh);
    spike_times{:,iCh} = st;
    for iSt =1:length(st)
        if st(iSt)-prewave>45&&st(iSt)+postwave<st(end)
            wave(:,iSt) = naLFP(st(iSt)-prewave:st(iSt)+postwave);
        end
    end
    if ~isempty(wave)
        mwave(:,iCh) = mean(wave,2);
        swave(:,iCh) = std(wave,0,2);
    end
    fclose(fp);
    clear LFP
    clear wave
% % %     naLFP = Filter_for_spikes(LFP,sFreq);
% % %     st = Spikes_From_Threshold(naLFP,thresh);
% % %     spike_times{:,iCh} = st;
% % %     D(:,iCh) = naLFP;
% % %     fclose(fp);
% % %     clear LFP
end
fclose all
% figure
% clf

% skip = 1;
% plot_LFP(D(1:skip:end,:),sFreq/skip,[],channels)
%%
DuV = D*RHD.bit_to_uvolt_conversion;
figure
time = (1:length(DuV(:,1)))/sFreq;
shft=max(max(DuV)-min(DuV));
for iL = 1:length(spike_times)
    plot(time,DuV(:,iL)+shft*iL)
    if ~isnan(spike_times{:,iL})
        if length(spike_times{:,iL})>2
            spike_times_sec = spike_times{:,iL}/sFreq;
            line([spike_times_sec spike_times_sec],[shft*iL-shft*.5 shft*iL-shft*.55] ,'color','r');
        end
    end
    ytk(iL) = shft*iL;
    text(max(time),shft*iL,sprintf('amp-%s-%03d',amp,channels(iL)));
    hold on
end
nt = roundn(shft/3,1);
% nt = 50
lytk = ytk-nt;
hytk = ytk+nt;
tks = [ytk,lytk,hytk];
tiks = sort(tks);
yticks(tiks')
% poop = '' 
ytl = {['-',num2str(nt)], ' 0', num2str(nt)};
[ytlab{1:iL}] = deal(ytl);
ytlabel = horzcat(ytlab{:});
yticklabels(ytlabel)
g=gca;
g.YLim = [0 shft*(iL+1)];
xlabel('Time (s)')
ylabel('Filtered LFP (uV)')
% FullScreenFigs
axis tight


if exist('mwave') && plotwave==1
    mwave_uV = mwave*RHD.bit_to_uvolt_conversion;
    swave_uV = swave*RHD.bit_to_uvolt_conversion;
    figure;
    for iCh = 1:length(channels)
        if  iCh <= length(mwave(1,:))
            numplt = ceil(length(channels)/sqrt(length(channels)));
            if mod(sqrt(length(channels)),2)==0 || mod(sqrt(length(channels)),2) > 0.5
                subplot(numplt,numplt,iCh); % this only works with an even number of channels
            else
                subplot(numplt,numplt-1,iCh); % this only works with an even number of channels
            end
            xax = (1:length(mwave_uV))/30;
            plot(xax,mwave_uV(:,iCh),'color',[0 0 1]);
            hold on
            plot(xax,mwave_uV(:,iCh)-swave_uV(:,iCh),'color',[.5 .5 1]);
            hold on
            plot(xax,mwave_uV(:,iCh)+swave_uV(:,iCh),'color',[.5 .5 1]);
            g=gca;
            posi = g.YLim(1) + diff(g.YLim)*.25;
            text(max(xax)*.85,posi,sprintf('amp-%s-%03d',amp,channels(iCh)));
            xlabel('Time (ms)');
            ylabel('Amplitude (uV)');
%             pubify_figure_axis;
        end
    end
end

FullScreenFigs
