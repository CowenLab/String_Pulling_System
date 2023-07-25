function h = SPEC_plot_spectrogram_by_condition(SPEC,x_time,fq_labels,validIX,regionID,region_labels, xlab,ylab,colorlab,cax, cmap)
% Restrict SPEC to the frequencies of interest before passing it into this
% function.
%
% PLot the average response across trials.
% SPEC is a 4d matrix col 1 = time, col 2 = frequencies, col 3 = injection,
% col 4 = group.
x_expansion_factor = 0.02;
if nargin < 10
    cax = [];
end
if nargin < 11
    cmap = jet;
end

for iReg = 1:length(region_labels)
    reg = region_labels{iReg};
    IX =  validIX & strcmp(regionID,reg)'; tit = reg;
    SPECreg = SPEC(:,:,:,IX);
    if sum(IX)==0
        error('No records found')
    end
    
    MnSPC = nanmean(SPECreg,4);
    M = nanmean(MnSPC,3);
    %     M = convn(M,halfhan/sum(halfhan),'same');
    %     M = convn(M',hanfq/sum(hanfq),'same')';
    %     M = sgolayfilt(M',3,svgol_winsize_fq)';
    %
    h(iReg) = subplot_ij(length(region_labels),1,iReg,1,0,x_expansion_factor);
    imagesc(x_time,fq_labels,M')
    if ~isempty(cax)
        caxis(cax)
    end
    hold on; axis xy;a = axis;
    plot([0 0 ],a(3:4),'w','LineWidth',3)
    plot([0 0 ],a(3:4),'k:','LineWidth',3)
    %     colormap(inferno)
    if iReg == length(region_labels)
        xlabel(xlab)
    else
        set(gca,'XTickLabel','')
    end
    
    if iReg == 1
        title([tit ' All Injections'])
        
    else
        title(reg)
    end
    ylabel(ylab)
    pubify_figure_axis
end
if isempty(cax)
    equalize_color_axes(h);
end
subplot(h(1))
colorbar_label(colorlab);
colormap(cmap)
