function [OUT] = LK_Find_best_80Hz_LFP()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine which channel or channel combo has the strongest 80 Hz
% oscillation
% Cowen 2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global DIRS
OUT = [];
[GP,E,EVT,SP,RHD,META,DEPTHS,TS] = LK_Load_Important_Things();
SES = LK_Session_Info();
OUT.SES = SES;
OUT.aborted = false;

lfp_dir = fullfile(DIRS.LFP_Dir,SES.rat_str,SES.session_str,'LFP');
[~,LFP_files] = find_files(fullfile(lfp_dir,'amp*.mat'));
E = LK_Load_Events_From_Excel('Event_times.xlsx');
t_dopa_start_end_min(1) = E.MinFromStart(E.EventID == 'LDOPAInjectionStart')+40;
t_dopa_start_end_min(2) = t_dopa_start_end_min(1) + 20;
t_dopa_start_end_uS = t_dopa_start_end_min*60e6;
for iF = 1:length(LFP_files)
    LFP = LK_Load_and_Clean_LFP(LFP_files{iF});
    if iF == 1
        IX = LFP.t_uS > t_dopa_start_end_uS(1) & LFP.t_uS < t_dopa_start_end_uS(2);
        L = zeros(sum(IX),length(LFP_files));
        L(:,1) = LFP.LFP(IX);
    else
        L(:,iF) = LFP.LFP(IX);
    end
end
filts = SPEC_create_filters({'gamma_80' [65 75]},LFP.sFreq);
[OUT.INFO] = SPEC_find_best_channel_combo(L,filts{1},filts{2});
% best combo
plot_me(OUT)

OUT.best_non_reref = LFP_files{OUT.INFO.best_non_reref}
OUT.best_reref_combo{1} = LFP_files{OUT.INFO.best_reref_combo(1)};
OUT.best_reref_combo{2} = LFP_files{OUT.INFO.best_reref_combo(2)};
OUT.best_reref_combo
figure
for ii = 1:Cols(L)
    subplot(ceil(Cols(L)/8),8,ii)
    pwelch(L(:,ii),LFP.sFreq,LFP.sFreq/2,256,LFP.sFreq)
    title(LFP_files{ii},'FontSize',7)
end
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_me(OUT)
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