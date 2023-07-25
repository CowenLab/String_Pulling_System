function [h,pvals] = SPEC_mean_power_diff_by_fq_region_and_interval(SPEC,validIX,regionID,region_labels, xlab,ylab,plot_type,yrng,reg2cmp,clr,offset)
% Restrict SPEC to the frequencies of interest before passing it into this
% function.
%
% PLot the average response across trials.
% SPEC is a 4d matrix col 1 = time, col 2 = frequencies, col 3 = injection,
% col 4 = group.
% This asks the overall question - is activity greater than baseline?
%
if nargin < 8
    reg2cmp = [1 5];
end
if nargin < 9
    clr = 'k';
end
if nargin < 10
    offset = 0;
end

Z_SCORE_IT = true;
do_vert = false;
PLOT_POINTS = false;
pvals = [];
x_expansion_factor = 0.02;
make_sample = false;
mk_size = 3;
pvals = NaN(length(region_labels),size(SPEC,2));
if size(SPEC,2) ~= length(xlab)
    error('Number of frequencies in SPEC and xlab not consistent')
end

for iReg = 1:length(region_labels)
    reg = region_labels{iReg};
    IX =  validIX & strcmp(regionID,reg)';
    SPECreg = SPEC(:,:,:,IX);
    SPECreg = SPECreg(:,:,reg2cmp(2),:) - SPECreg(:,:,reg2cmp(1),:) ; % Average across epochs.
    
    MnSPC = squeeze(trimmean(SPECreg,10,1))'; % squeez across all time
    M = MnSPC;
    [~,pvals(iReg,:)] = ttest(M);
%      h(iReg) = subplot_ij(1,length(region_labels),1,iReg,x_expansion_factor,[]);
    if do_vert
        h(iReg) = subplot(length(region_labels),1,iReg);
    else
        h(iReg) = subplot(1,length(region_labels),iReg);
    end
    switch plot_type
        case 'boxplot'
            boxplot(M,'notch','on');
        case 'errorbar'
            if PLOT_POINTS
                for ii = 1:Rows(M)
                    plot((1:Cols(M))+offset,M(ii,:),'o','MarkerSize',mk_size,'Color',clr)
                    hold on
                end
            end
            hh = errorb((1:Cols(M))+offset,nanmean(M), Sem(M),'barwidth',1.5);
            set(hh,'Color',clr)
        otherwise
            error('wrong type of plot')
    end
    hold on
    axis tight
    if  do_vert
        if  iReg == length(region_labels)
            set(gca,'XTickLabel',xlab)
            set(gca,'XTickLabelRotation',45)
        else
            set(gca,'XTickLabel','')
        end
        ylabel(ylab)
        
    else
        set(gca,'XTickLabel',xlab)
        set(gca,'XTickLabelRotation',45)
        if iReg == 1
            ylabel(ylab)
            
        else
            set(gca,'YTickLabel','')
        end
    end
    title(reg)
    a = axis;
    a(1) = 0.4;
    if ~isempty(yrng)
        a(3:4) = yrng;
    end
    axis(a);
    plot(a(1:2),[0 0],'k:','LineWIdth', 1)
    
    pubify_figure_axis;
end
if isempty(yrng)
    equalize_y_axes(h);
end


