function [OUT] = LK_Evaluate_and_Clean_LFP()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the important files that go with just about any analysis...
% Cowen 2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global DIRS
OUT = [];
[GP,E,EVT,SP,RHD,META,DEPTHS,TS] = LK_Load_Important_Things();
PLOT_IT = true;
plot_type = 'spectrogram';
% plot_type = 'wavelet';
freqrange = 3:1:120;
spec_win_size_sec = 4;
resolution_per_octave = 16;
SES = LK_Session_Info();
OUT.SES = SES;
OUT.aborted = false;

lfp_dir = fullfile(DIRS.LFP_Dir,SES.rat_str,SES.session_str,'LFP');
[~,LFP_files] = find_files(fullfile(lfp_dir,'amp*.mat'));
% L = LK_Load_and_Clean_LFP(LFP_files{24},LFP_files(1:10));
lfp_info = readtable('LFP_INFO_auto_generated.csv');
IMU = LK_Load_and_Process_IMU;
POS = LK_Load_and_Clean_POS;
E = LK_Load_Events_From_Excel('Event_times.xlsx');
t_LDOPA_min = E.MinFromStart(E.EventID=='LDopaInjectionStart' | E.EventID=='LDOPAInjectionStart');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plan: Find a period of higher movement. Look at a 1 minute interval in
% that period. Use this to judge the artifact threshold level and the best
% channels.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
thj = prctile(IMU.absjerk,99.9);
thp = prctile(POS.speed,99.5);
thp_low = prctile(POS.speed,5.5);
subplot(2,1,1)
plot(IMU.t_uS/60e6, IMU.absjerk)
plot_horiz_line_at_zero(thj)
subplot(2,1,2)
plot(POS.Time_uS/60e6, POS.speed)
plot_horiz_line_at_zero(thp)

t_min = POS.Time_uS/60e6;
peak_ix = find(t_min > 10 & POS.speed > thp);
low_ix = find(t_min > 10 & envelope_cowen(POS.speed) < thp_low);
eval_interval_min = [t_min(peak_ix(1))-1.5 t_min(peak_ix(1))+1.5];

for iF = 1:length(LFP_files)
    load(fullfile(lfp_dir,LFP_files{iF}),'LFP');
    if iF == 1
        sFreq = LFP.LFP_sFreqj;
        t_min = (0:(length(LFP.data)-1))/sFreq/60;
        GIX = t_min > eval_interval_min(1) & t_min < eval_interval_min(2);
        L = zeros(sum(GIX),length(LFP_files));
    end
    L(:,iF) = double(LFP.data(GIX))*LFP.to_uV_conversion;
    
end


groups = 1:7:length(LFP_files);
groups(end) = length(LFP_files);
L(abs(L)>500) = nan;
for ii = 1:length(groups)-1
    figure
    plot_LFP(L(:,groups(ii):groups(ii+1)),sFreq,[],LFP_files(groups(ii):groups(ii+1)))
    title(SES.title_str)
end
% [OUT, stats] = SPEC_rereference(L(:,22),L(:,1:10));

%% Loop over each file. Spectrogram
if 0
    for iF = 1:length(LFP_files)
        load(fullfile(lfp_dir,LFP_files{iF}),'LFP');
        sFreq = LFP.LFP_sFreqj;
        
        L = double(LFP.data)*LFP.to_uV_conversion;
        t_min = (0:(length(L)-1))/sFreq/60;
        GIX = t_min > eval_interval_min(1) & t_min < eval_interval_min(2);
        figure(2)
        subplot(2,1,1)
        plot(t_min(GIX),L(GIX))
        title(LFP_files{iF})
        xlabel('min')
        subplot(2,1,2)
        spectrogram(L(GIX),sFreq*spec_win_size_sec,sFreq*spec_win_size_sec/2,freqrange,sFreq,'yaxis')
        pause()
        %     switch plot_type
        %         case 'spectrogram'
        %             figure(1)
        %             clf
        %             spectrogram(L,sFreq*spec_win_size_sec,sFreq*spec_win_size_sec/2,freqrange,sFreq,'yaxis')
        %             caxis([-30 30])
        %             title(LFP_files{iF})
        %             title(sprintf('%1.3f to %1.3f min (inj at %1.3f)',t_LDOPA_min + time_around_injection_min(1) ,t_LDOPA_min + time_around_injection_min(2),t_LDOPA_min ))
        %         case 'wavelet'
        %             % Can't get wavelet to work for some reason. Grr.
        %             cwt(L,'bump',sFreq,'FrequencyLimits',freqrange([1 end]));
        %     end
        
    end
end
