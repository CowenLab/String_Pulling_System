function [OUT] = LK_Find_80Hz_events()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Identify 80 Hz events within the L-DOPA periods
%
% Cowen 2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PLOT_IT = true;
TEST_OTHER_FILTS = true;

SES = LK_Session_Info();
OUT = [];
OSC = Oscillation_frequencies;
[GP,E] = LK_Load_Important_Things();
% Thresholds for event detection.
th_high = 3;
th_low = 1;
th_non_event = 2.5;

OUT.th_high = th_high;
OUT.th_low = th_low;
OUT.th_non_event = th_non_event;
OUT.SES = SES;
load('./Processed_Data/best_channels_gamma_80.mat','OUT')
OUT.LFP_file = OUT.best_non_reref;

%% Load the best non-reref.
if exist(fullfile('LFP',OUT.best_non_reref),'file')
    % load if stored locally.
    LFP = LK_Load_and_Clean_LFP('./LFP',OUT.best_non_reref);
    
else
    global DIRS
    lfp_dir = fullfile(DIRS.LFP_Dir,SES.rat_str,SES.session_str,'LFP');
    LFP = LK_Load_and_Clean_LFP(lfp_dir, OUT.best_non_reref);
end
OUT.sFreq = LFP.sFreq;

filts = SPEC_create_filters({'gamma_80' [65 75]}, LFP.sFreq);
t_LDOPA_inj_min = E.MinFromStart(E.EventID == 'LDOPAInjectionEnd');
t_LDOPA_inj_uS = t_LDOPA_inj_min*60e6;
t_LDOPA_effect_win = [30 50] + t_LDOPA_inj_min;
IXeff = LFP.t_uS >t_LDOPA_effect_win(1)*60e6 & LFP.t_uS < t_LDOPA_effect_win(2)*60e6;
IXpostLDOPA = LFP.t_uS > t_LDOPA_inj_uS & LFP.t_uS < LFP.t_uS(end);
% Create an index of 80 power.
L = zeros(length(LFP.LFP),length(filts));
for ii = 1:length(filts)
    L(:,ii) = filtfilt(filts{ii},LFP.LFP);
end
% pow80 = (abs(hilbert(L(:,1))) - abs(hilbert(L(:,2))))./ (abs(hilbert(L(:,1))) + abs(hilbert(L(:,2))));
pow80z = zscore(abs(hilbert(L(:,1))) - abs(hilbert(L(:,2)))); %could do regression too.

if TEST_OTHER_FILTS
    % Contrast with wavelet approach.
    [cfs_tmp,frq_tmp] = cwt(LFP.LFP(IXeff),'bump',LFP.sFreq,'FrequencyLimits',OSC.gamma_80);
    [cfs] = cwt_fix(cfs_tmp,frq_tmp,OSC.gamma_80(1):1:OSC.gamma_80(2));
    %
    figure
    plot(LFP.t_uS(IXeff),LFP.LFP(IXeff))
    hold on
    plot(LFP.t_uS(IXeff),L(IXeff,1))
    plot(LFP.t_uS(IXeff),abs(hilbert(L(IXeff,1))))
    plot(LFP.t_uS(IXeff),pow80z(IXeff))
    plot(LFP.t_uS(IXeff),nanmean(cfs,2))
    legend('raw','80f','hil','pow80','cwt')
    CC = corr([abs(hilbert(L(IXeff,1))) pow80z(IXeff) nanmean(cfs,2)]);
end
% Detect events..

% Now run this on all data after the L-DOPA injetion.

[event_times] = find_intervals([LFP.t_uS(IXpostLDOPA) pow80z(IXpostLDOPA)], th_high, th_low);
[non_event_times] = find_intervals([LFP.t_uS(IXpostLDOPA) -1*pow80z(IXpostLDOPA)], th_non_event, th_low);
dur_s = (event_times(:,2) - event_times(:,1))/1e6;
event_times = event_times(dur_s > 0.050,:);
dur_s = (non_event_times(:,2) - non_event_times(:,1))/1e6;
non_event_times = non_event_times(dur_s > 0.050,:);
%%
if PLOT_IT
    figure
    plot(LFP.t_uS(IXeff),LFP.LFP(IXeff))
    hold on
    plot(LFP.t_uS(IXeff),L(IXeff,1))
    yyaxis right
    plot(LFP.t_uS(IXeff),pow80z(IXeff))
    plot(event_times(:,1),ones(size(event_times(:,1)))*th_low,'g>')
    plot(event_times(:,2),ones(size(event_times(:,1)))*th_low,'r<')
    
    plot(non_event_times(:,1),ones(size(non_event_times(:,1)))*0,'c>')
    plot(non_event_times(:,2),ones(size(non_event_times(:,1)))*0,'m<')
    
    plot_ref_line(th_high,'orientation','horiz')
    plot_ref_line(th_low,'orientation','horiz')
    set(gca,'XLim',t_LDOPA_effect_win*60e6)
    
    figure
    histogram((event_times(:,2) - event_times(:,1))/1e6,100)
    xlabel('s')
    figure
    histogram((non_event_times(:,2) - non_event_times(:,1))/1e6,100)
    xlabel('s')
    
    figure
    [V,e] = histcounts(event_times(:,1),t_LDOPA_inj_uS:30e6:event_times(end));
    x = e(1:end-1)-(e(2)-e(1))/2;
    plot(x/60e6,V);
    xlabel('min')
    title('n 80Hz events post injection')
    figure
    plot(event_times(:,1)/60e6,conv_filter((event_times(:,2)-event_times(:,1))/1e6,hanning(50)/sum(hanning(50))))
    ylabel('duration s')
    xlabel('min')
    title('80Hz durations post injection')
    
end
%% Go through each event and calculate stuff.
D = [LFP.t_uS(IXpostLDOPA) LFP.LFP(IXpostLDOPA) L(IXpostLDOPA,1) pow80z(IXpostLDOPA)];
G = [];
SIG = [];
for iE = 1:Rows(event_times)
    Y = Restrict(D,event_times(iE,:));
    pow = abs(hilbert(Y(:,3)));
    [mx,ix] = max(pow);
    %     plot(Y(:,2:end))
    %     hold on
    %     plot(pow)
    G(iE).st_uS = event_times(iE,1);
    G(iE).ed_uS = event_times(iE,2);
    G(iE).t_maxpow_uS = Y(ix,1);
    G(iE).ix_maxpow = ix; % could be a standin for the rate at whcih power peaks.
    G(iE).dur_s = (event_times(iE,2) - event_times(iE,1))/1e6;
    G(iE).max_pow = mx;
    G(iE).max_signoise_z = max(Y(:,4));
    [fq_ga] = instfreq(Y(:,2),LFP.sFreq,'FrequencyLimits',[74 97]);
    G(iE).fq = mean(fq_ga);
    
    % Find the peak with the greatest power.
    [pks,locs] = findpeaks(Y(:,3));
    [~,ix] = max(pks);
    G(iE).max_peak_uS = Y(locs(ix),1);
    G(iE).start_peak_uS = Y(locs(1),1);
    [pks,locs] = findpeaks(-1*Y(:,3));
    [~,ix] = max(pks);
    G(iE).max_trough_uS = Y(locs(ix),1);
    %     figure
    %     plot(Y(:,1),Y(:,3))
    %     hold on
    %     plot(G(iE).max_peak_uS,max(Y(:,3)),'r*')
    %     plot(G(iE).min_peak_uS,min(Y(:,3)),'g*')
    %     plot(G(iE).start_peak_uS,max(Y(:,3)),'c*')
    
    SIG{iE} = single(Y(:,2));
end
OUT.GAM = struct2table(G);
OUT.SIG = SIG;
OUT.non_event_times = non_event_times;
GE = OUT;
save(fullfile('.','Processed_Data','gamma_80_events.mat'),'GE');
