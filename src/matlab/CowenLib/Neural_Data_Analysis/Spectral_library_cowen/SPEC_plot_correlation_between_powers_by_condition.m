function [h,p] = SPEC_plot_correlation_between_powers_by_condition(SPEC,validIX,regionID,region_labels,fq_labels)
%
nFreqs = size(SPEC,2);
ix = triu(ones(nFreqs),1);
[i,j] = ind2sub([nFreqs nFreqs],find(triu(ones(nFreqs),1)>0));
x_expansion_factor = 0.02;

clrs = lines(Cols(SPEC));
ylab = 'Fisher r';
h = []; hh = [];
p = [];
cnt =1;
for iReg = 1:length(region_labels)
    reg = region_labels{iReg};
    IX =  validIX & strcmp(regionID,reg)';
    SPECreg = SPEC(:,:,:,IX);
    for iInj = 1:size(SPECreg,3)
        
        % Now you have the relevant sets. For EACH SESSION, computer the r
        % values and then average these r values.
        for iSes = 1:size(SPECreg,4)
            M = squeeze(SPECreg(:,:,iInj,iSes));
            R(:,:,iSes) = corrcoef(M);
        end
        R =  fisher_Z_transform(R);
        MnSPC = nanmean(R,3);
        SESPC = Sem(R,3);
        
        h(cnt) = subplot(length(region_labels),size(SPECreg,3),cnt);
        lab = [];
        m = [];
        s = [];
        for ii = 1:length(i)
            p(ii,iInj,iReg) = signrank(squeeze(R(i(ii),j(ii),:)));

            m(ii) = MnSPC(i(ii),j(ii));
            s(ii) = SESPC(i(ii),j(ii));
            lab{ii} = [fq_labels{i(ii)} 'to' fq_labels{j(ii)}];
        end
        errorb(1:length(m),m,s)
        hold on
        axis tight
        plot_horiz_line_at_zero

        set(gca,'XTick',1:length(m))
        if iReg == length(region_labels)
            set(gca,'XTickLabel',lab)
            set(gca,'XTickLabelRotation',45)
            xlabel('Frequencies compared')
        else
            set(gca,'XTickLabel',[])
            
        end
        title(sprintf('%s %d',region_labels{iReg},iInj))
        
        if iInj == 1
            ylabel(ylab)
        end
        set(gca,'FontSize',8)
        cnt = cnt + 1;
        
    end
end
equalize_axes(h);
% for ii = 1:length(h)
%     axis(h(ii))
%     plot_horiz_line_at_zero
% end
% set(h,'Ylim',[-.5 .6])
% equalize_color_axes(h)
