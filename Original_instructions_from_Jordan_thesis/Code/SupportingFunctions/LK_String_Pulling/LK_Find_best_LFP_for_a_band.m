function [OUT] = LK_Find_best_LFP_for_a_band(sig_name)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine which channel or channel combo has the strongest
% oscillation
%
% Cowen 2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global DIRS
if nargin < 1
    sig_name = 'gamma_50';
end
OUT = [];
% [GP,E,EVT,SP,RHD,META,DEPTHS,TS] = LK_Load_Important_Things();
SES = LK_Session_Info();
OUT.sig_name = sig_name;
OUT.SES = SES;
OUT.aborted = false;
fqs = 1:.5:170;

lfp_dir = fullfile(DIRS.LFP_Dir,SES.rat_str,SES.session_str,'LFP');
[~,LFP_files] = find_files(fullfile(lfp_dir,'amp*.mat'));
E = LK_Load_Events_From_Excel('Event_times.xlsx');
switch sig_name
    case {'gamma_80' 'gamma_50'}
        t_start_end_min(1) = E.MinFromStart(E.EventID == 'LDOPAInjectionStart')+40;
        t_start_end_min(2) = t_start_end_min(1) + 20;
        
    case 'beta'
        if any(E.EventID=='TreadmillStart')
            disp('Found Treadmill')
            tmp1 = E.MinFromStart(E.EventID == 'TreadmillStart');
            tmp2 = E.MinFromStart(E.EventID == 'TreadmillStop');
            %
            t_start_end_min(1) = tmp1(1);
            t_start_end_min(2) = tmp2(1);
            
            %             t_start_end_min(1) = tmp1(1)-20;
            %             t_start_end_min(2) = tmp1(1)-2;
            
        else
        end
        
    otherwise
        if any(E.EventID=='KetInjectionStart')
            disp('Found Ketamine')
            
            t_start_end_min(1) = E.MinFromStart(E.EventID == 'KetInjectionStart')+10;
            t_start_end_min(2) = t_start_end_min(1) + 20;
        end
        
end
t_start_end_uS = t_start_end_min*60e6;
for iF = 1:length(LFP_files)
    LFP = LK_Load_and_Clean_LFP(lfp_dir, LFP_files{iF});
    if iF == 1
        IX = LFP.t_uS > t_start_end_uS(1) & LFP.t_uS < t_start_end_uS(2);
        L = zeros(sum(IX),length(LFP_files));
        L(:,1) = LFP.LFP(IX);
    else
        L(:,iF) = LFP.LFP(IX);
    end
end
switch sig_name
    case 'gamma_50'
        filts = SPEC_create_filters({'gamma_50' 'beta2'},LFP.sFreq);
    case 'theta'
        filts = SPEC_create_filters({'theta' 'delta'},LFP.sFreq);
    case 'beta'
        filts = SPEC_create_filters({[25 37] [15 21]},LFP.sFreq);
    case 'gamma_80'
        filts = SPEC_create_filters({'gamma_80' [65 75]},LFP.sFreq);
    case 'HFO'
        filts = SPEC_create_filters({'HFO' [110 125]},LFP.sFreq);
end
[OUT.INFO] = SPEC_find_best_channel_combo(L,filts{1},filts{2});
OUT.filts = filts;
% best combo

OUT.best_non_reref = LFP_files{OUT.INFO.best_non_reref};
OUT.best_reref_combo{1} = LFP_files{OUT.INFO.best_reref_combo(1)};
OUT.best_reref_combo{2} = LFP_files{OUT.INFO.best_reref_combo(2)};

% make the last col the re-reffed data.
RR = L(:,OUT.INFO.best_reref_combo(1)) - L(:,OUT.INFO.best_reref_combo(2)) ;

OUT
if exist('Processed_Data','dir')
    save(['./Processed_Data/best_channels_' sig_name '.mat'],'OUT')
else
    save(['best_channels_' sig_name '.mat'],'OUT')
end

figure
subplot(2,1,1)
pwelch(L(:,OUT.INFO.best_reref_combo(1)),LFP.sFreq,LFP.sFreq/2,fqs,LFP.sFreq)
grid off
pubify_figure_axis
title('')
ylabel('')
subplot(2,1,2)
pwelch(L(:,OUT.INFO.best_reref_combo(2)),LFP.sFreq,LFP.sFreq/2,fqs,LFP.sFreq)
grid off
title('')
ylabel('')
pubify_figure_axis
equalize_y_axes

figure
pwelch(RR,LFP.sFreq,LFP.sFreq/2,fqs,LFP.sFreq)
title('re reffed signal')

plot_me(OUT,LFP_files,sig_name)
plot_all_LFP(L,LFP,LFP_files,sig_name)
% plot_all_LFP_spec(LFP,LFP_files,sig_name) - needs cleaning
% Now that this was selected, show the spectrogram.
files = {OUT.best_non_reref OUT.best_reref_combo{1} OUT.best_reref_combo{2} 'reref'};
chnls = [OUT.INFO.best_non_reref OUT.INFO.best_reref_combo Cols(L)];
%%
figure
for iF = 1:length(files)
    if strcmp(files{iF},'reref')
        a = LK_Load_and_Clean_LFP(lfp_dir, OUT.best_reref_combo{1});
        LFP = LK_Load_and_Clean_LFP(lfp_dir, OUT.best_reref_combo{2});
        LFP.LFP = a.LFP-LFP.LFP;
    else
        LFP = LK_Load_and_Clean_LFP(lfp_dir, files{iF});
        
    end
    % whiten: Does not work so great.
    %     LFP.LFP = SPEC_whiten_data_AR(LFP.LFP,3);
    subplot(length(files),1,iF)
    %      spectrogram(LFP.LFP,LFP.sFreq*5,LFP.sFreq*3,fqs, LFP.sFreq,'yaxis');
    [S,w,t] = spectrogram(LFP.LFP,LFP.sFreq*5,LFP.sFreq*3,fqs, LFP.sFreq);
    t_min = t/60;
    S = 10*log10(abs(S))';
    %     p = prctile(S,[.5 99.5]);
    %     BIX = S<p(1,:);
    %     BIX = BIX | S>p(2,:);
    %     S(BIX) = nan;
    Sn = movmedian(S,30,'omitnan');
    Sn = conv_filter(S,hanning(15)/sum(hanning(15)));
    
    BASEIX = t_min < 10;
    Sb = Sn-nanmean(Sn(BASEIX,:),1);
    Sb = Sb./nanstd(Sn(BASEIX,:),[],1);
    
    imagesc(t_min,fqs,Sn');
    
    axis xy
    mkrs = cat2cell(E.EventID);
    plot_markers(E.MinFromStart,1)
    title(files{iF})
    ylabel('Hz')
    colorbar
    caxis(prctile(Sn(:),[1 99]))
    
    if iF == length(files)
        h = plot_markers(E.MinFromStart,1,mkrs);
        
        set(h,'Rotation',45)
        set(h,'FontSize',5)
        xlabel('min')
    end
end
POS = LK_Load_and_Clean_POS;
s = movmedian(POS.speed,100,'omitnan');
s = conv_filter(s,hanning(1500));
figure
plot(POS.Time_uS/60e6,s)
axis tight

%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_me(OUT,LFP_files,sig_name)
figure
subplot(1,2,1)
barh(OUT.INFO.ratings_non_reref)
axis tight
set(gca,'YTick',1:length(OUT.INFO.ratings_non_reref))
set(gca,'YTickLabel',LFP_files,'FontSize',7)
title(['Sig to Noise ' sig_name])
subplot(1,2,2)
imagesc(OUT.INFO.scores_by_combo)
set(gca,'YTick',1:length(OUT.INFO.ratings_non_reref))
set(gca,'YTickLabel',LFP_files,'FontSize',5)
set(gca,'XTick',1:length(OUT.INFO.ratings_non_reref))
set(gca,'XTickLabel',LFP_files,'FontSize',5)
set(gca,'XTickLabelRotation',90)
axis xy

end

function plot_all_LFP(L,LFP,LFP_files,sig_name)
figure
for ii = 1:Cols(L)
    subplot(ceil(Cols(L)/8),8,ii)
    pwelch(L(:,ii),LFP.sFreq,LFP.sFreq/2,256,LFP.sFreq)
    title(LFP_files{ii},'FontSize',7)
end
sgtitle(sig_name)
end

function plot_all_LFP_spec(LFP,LFP_files,sig_name)
figure
for iF = 1:length(LFP_files)
    fqs = 1:.5:100;
    LFP = LK_Load_and_Clean_LFP(LFP_files{iF});
    
    subplot(ceil(length(LFP_files)/8),8,iF)
    spectrogram(LFP.LFP,LFP.sFreq*10,LFP.sFreq*5,fqs, LFP.sFreq,'yaxis')
    %     pwelch(L(:,ii),LFP.sFreq,LFP.sFreq/2,256,LFP.sFreq)
    title(LFP_files{iF},'FontSize',7)
end
sgtitle(sig_name)
end