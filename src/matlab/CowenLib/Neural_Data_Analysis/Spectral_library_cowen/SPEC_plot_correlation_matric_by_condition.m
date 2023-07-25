function h = SPEC_plot_correlation_matric_by_condition(CC,xyvals,VALIDIX,cats,cats_to_plot,cb_lab,nrow_startrow)
if nargin < 6
    nrow_startrow = [1 1];
end
h = zeros(length(cats_to_plot),1);
for iCat = 1:length(cats_to_plot)
    IX = VALIDIX & strcmpi(cats,cats_to_plot{iCat})';
    CCi = CC(:,:,IX);
    CCim = nanmean(CCi,3);
    h(iCat) = subplot_ij(nrow_startrow(1),length(cats_to_plot),nrow_startrow(2),iCat);
    imagesc(xyvals,xyvals,CCim)
    axis square
    pubify_figure_axis
    title(cats_to_plot{iCat});
    axis xy
end
colormap(jet)
colorbar_label(cb_lab)
