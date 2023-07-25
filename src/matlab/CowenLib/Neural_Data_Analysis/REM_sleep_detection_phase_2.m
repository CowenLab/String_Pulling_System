function [O] = REM_sleep_detection_phase_2(P1)
% FROM PAPERS:
O = [];
% Kreuzer, M., Polta, S., Gapp, J., Schuler, C., Kochs, E. F., & Fenzl, T. (2015). Sleep scoring made easy - Semi-automated sleep analysis software and manual rescoring tools for basic sleep research in mice. MethodsX, 2, 232–240. https://doi.org/10.1016/j.mex.2015.04.005
%%% NO MENTION OF ELECTRODE PLACEMENT IN Kreuzer.
% Louis, R. P., Lee, J., & Stephenson, R. (2004). Design and validation of a computer-based sleep-scoring algorithm. Journal of Neuroscience Methods, 133(1–2), 71–80. https://doi.org/10.1016/j.jneumeth.2003.09.025
%%% STATE EEG electrode over frontal gets you better alpha and delta so
clrs = lines(10);
INDIVIDUALS = false;

Theta_thresh = 2;
Mov_thresh = prctile(P1.MVT,60);
P1.LDMV_STATE = P1.LD_STATE;
P1.LDMV_STATE(P1.LD_STATE == 'REM' & (P1.Tindex < Theta_thresh | P1.MVT(:,1) > Mov_thresh)) = 'UNKNOWN';

PLOT_IT = false;
u = {'REM' 'NREM' 'UNKNOWN'};

% Clean up some that might still be a bit crappy...


figure
subplot_ij(2,3,1,1)
scatter(P1.Tindex,P1.Dindex,[],P1.STATE)
xlabel('theta');
ylabel('delta');
title('Hard Thresh')

subplot_ij(2,3,2,1)
plot_confidence_intervals(P1.psd_fqs,P1.psd(P1.STATE=='REM',:),[],clrs(1,:))
hold on
plot_confidence_intervals(P1.psd_fqs,P1.psd(P1.STATE=='NREM',:),[],clrs(2,:))
plot_confidence_intervals(P1.psd_fqs,P1.psd(P1.STATE=='UNKNOWN',:),[],clrs(3,:))
legend_color_text({'REM','NREM','UNKNOWN'},{clrs(1,:) clrs(2,:) clrs(3,:)});
axis tight
xlabel('Hz')


subplot_ij(2,3,1,2)
scatter(P1.Tindex,P1.Dindex,[],P1.LD_STATE)
% colormap(lines)
xlabel('theta');
ylabel('delta');
title('LD Cluster 1')

subplot_ij(2,3,2,2)
plot_confidence_intervals(P1.psd_fqs,P1.psd(P1.LD_STATE=='REM',:),[],clrs(1,:))
hold on
plot_confidence_intervals(P1.psd_fqs,P1.psd(P1.LD_STATE=='NREM',:),[],clrs(2,:))
plot_confidence_intervals(P1.psd_fqs,P1.psd(P1.LD_STATE=='UNKNOWN',:),[],clrs(3,:))
legend_color_text({'REM','NREM','UNKNOWN'},{clrs(1,:) clrs(2,:) clrs(3,:)});
axis tight
xlabel('Hz')

subplot_ij(2,3,1,3)
scatter(P1.Tindex,P1.Dindex,[],P1.LDMV_STATE)
xlabel('theta');
ylabel('delta');
title('LD Cluster P1.LDMV_STATE')

subplot_ij(2,3,2,3)
plot_confidence_intervals(P1.psd_fqs,P1.psd(P1.LDMV_STATE=='REM',:),[],clrs(1,:))
hold on
plot_confidence_intervals(P1.psd_fqs,P1.psd(P1.LDMV_STATE=='NREM',:),[],clrs(2,:))
plot_confidence_intervals(P1.psd_fqs,P1.psd(P1.LDMV_STATE=='UNKNOWN',:),[],clrs(3,:))
legend_color_text({'REM','NREM','UNKNOWN'},{clrs(1,:) clrs(2,:) clrs(3,:)});
axis tight
xlabel('Hz')

% 
% 
% % Show some AUTOMATICALLY classified REM and NREM states
% REMix = find(P1.LDMV_STATE =='REM');
% NREMix = find(P1.LDMV_STATE =='NREM');
% %%%%%%%%%%%%%%%%%%%%%%%%
% IX = P1.STATE =='REM' | P1.STATE =='NREM';
% [LD, LD_wt] = Linear_discriminant(Z_scores(P1.psd(IX,:)),P1.STATE(IX));
% MdlLinearZ = fitcdiscr(Z_scores([P1.psd P1.MVT]),P1.STATE);
% % MdlLinear = fitcdiscr(P1.psd(IX,:),P1.STATE(IX));
% MdlLinear = fitcdiscr([P1.psd P1.MVT],P1.STATE);
% C = predict(MdlLinear,[P1.psd P1.MVT]);
% figure
% subplot(2,2,1:2)
% 
% 
% plot_confidence_intervals(P1.psd_fqs,P1.psd(C=='REM',:),[],clrs(1,:))
% hold on
% plot_confidence_intervals(P1.psd_fqs,P1.psd(C=='NREM',:),[],clrs(2,:))
% plot_confidence_intervals(P1.psd_fqs,P1.psd(C=='UNKNOWN',:),[],clrs(3,:))
% legend_color_text({'REM','NREM','UNKNOWN'},{clrs(1,:) clrs(2,:) clrs(3,:)});
% axis tight
% xlabel('Hz')
% yyaxis right
% 
% subplot(2,2,3)
% scatter(P1.Tindex,P1.Dindex,[],C);
% xlabel('theta');
% ylabel('delta');
% 
% subplot(2,2,4)
% Error_bars(P1.MVT(C=='REM'),P1.MVT(C=='NREM'),P1.MVT(C=='UNKNOWN'))
% set(gca,'XTickLabel',{'REM' 'NREM' 'UNKNOWN'})
% ylabel('MVT')
% 
% 
% figure
% subplot(2,2,1:2)
% 
% plot_confidence_intervals(P1.psd_fqs,P1.psd(REMix,:),[],clrs(1,:))
% hold on
% plot_confidence_intervals(P1.psd_fqs,P1.psd(NREMix,:),[],clrs(2,:))
% legend_color_text({'REM','NREM'},{clrs(1,:) clrs(2,:)})
% axis tight
% xlabel('Hz')
% yyaxis right
% plot(P1.psd_fqs,LD_wt);
% ylabel('LD Wts')
% 
% subplot(2,2,3)
% Error_bars(P1.Tindex(REMix),P1.Dindex(REMix), P1.Tindex(NREMix),P1.Dindex(NREMix))
% set(gca,'XTickLabel',{'tREM' 'dREM' 'tNREM' 'dNREM' })
% 
% %     legend('Tidx','Didx')
% %     legend boxoff
% 
% %     set(gca,'XTickLabel',{'REM' 'NREM'})
% 
% subplot(2,2,4)
% Error_bars(P1.MVT(REMix),P1.MVT(NREMix))
% set(gca,'XTickLabel',{'REM' 'NREM'})
% ylabel('MVT')
%
%
%
if INDIVIDUALS
    nrem_cnt = 1;
    figure
    for iR = 1:length(REMix)
        clf
        subplot(2,2,1)
        x = 1:length(P1.LFP(REMix(iR),:));
        %     x = x/P1.sFreq;
        %     x = x/P1.sFreq;
        plot(x,P1.LFP(REMix(iR),:))
        hold on
        plot(x,P1.LFP(NREMix(iR),:)-200)
        axis tight
        
        subplot(2,2,2)
        plot(P1.psd_fqs,P1.psd(REMix(iR),:))
        hold on
        plot(P1.psd_fqs,P1.psd(NREMix(iR),:))
        legend('REM','NREM')
        legend boxoff
        axis tight
        xlabel('Hz')
        
        subplot(2,2,3)
        bar([P1.Tindex(REMix(iR)) P1.Dindex(REMix(iR));P1.Tindex(NREMix(iR)) P1.Dindex(NREMix(iR))])
        legend('Tidx','Didx')
        legend boxoff
        
        set(gca,'XTickLabel',{'REM' 'NREM'})
        
        subplot(2,2,4)
        
        bar([P1.MVT(REMix(iR)) P1.MVT(NREMix(iR))])
        set(gca,'XTickLabel',{'REM' 'NREM'})
        ylabel('MVT')
        
        nrem_cnt = nrem_cnt + 1;
        if nrem_cnt == length(NREMix)
            nrem_cnt = 1;
        end
        
        
        pause
    end
end
%
%
%
% for isubInterval = 1:(length(intervals_s)-1)
% end
%
% if PLOT_IT
%
%     figure
%     subplot(2,1,1)
%     plot(P1.Dindex)
%     hold on
%     plot(P1.Tindex)
%     legend('delta','theta')
%     if ~isempty(P1.MVT)
%         yyaxis right
%         plot(P1.MVT)
%         ylabel('mvt')
%     end
%
%     subplot(2,1,2)
%     imagesc([],P1.psd_fqs,P1.psd')
%
%     u = {'REM' 'NREM' 'UNKNOWN'};
%
%     clrs = lines(10);
%
%     figure
%     subplot(1,2,1)
%     for ii = 1:length(u)
%         plot_confidence_intervals(P1.psd_fqs,P1.psd(P1.STATE==u{ii},:),[],clrs(ii,:));
%         hold on
%     end
%     xlabel('Hz')
%     subplot(1,2,2)
%     scatter(P1.Tindex,P1.Dindex,[],P1.STATE)
%     xlabel('theta');
%     ylabel('delta');
%
%     figure
%     subplot(1,3,1)
%     histogram(P1.Dindex(:))
%     xlabel('delta');
%
%     subplot(1,3,2)
%     histogram(P1.Tindex(:))
%     xlabel('theta');
%     subplot(1,3,3)
%     histogram(P1.Tindex(:)./P1.Dindex(:))
%     xlabel('thetadelta ratio');
%
%
% end
