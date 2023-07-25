function h = PLOTSPEC_mean_power_diff_fq_region_and_interval(SPEC,validIX,regionID,region_labels, xlab,ylab,plot_type,yrng)
% Restrict SPEC to the frequencies of interest before passing it into this
% function.
%
% PLot the average response across trials.
% SPEC is a 4d matrix col 1 = time, col 2 = frequencies, col 3 = injection,
% col 4 = group.
% Compare epochs 1 and 5
x_expansion_factor = 0.02;
make_sample = false;
pvals = NaN(length(region_labels),size(SPEC,2));
if size(SPEC,2) ~= length(xlab)
    error('Number of frequencies in SPEC and xlab not consistent')
end

for iReg = 1:length(region_labels)
    reg = region_labels{iReg};
    IX =  validIX & strcmp(regionID,reg)'; 
    SPECreg = SPEC(:,:,:,IX);
    SPECreg = squeeze(nanmean(SPECreg,1)); % squeez across all time
    SPECreg_diff = squeeze(SPECreg(:,5,:) - SPECreg(:,1,:))';
    
    [~,pvals(iReg,:)] = ttest(SPECreg_diff);
    M = SPECreg_diff;
    h(iReg) = subplot_ij(1,length(region_labels),1,iReg,x_expansion_factor,[]);
    switch plot_type
        case 'boxplot'
            boxplot(M,'notch','on');
        case 'errorbar'
            for ii = 1:Rows(M)
                plot(1:Cols(M),M(ii,:),'b.','MarkerSize',10)
                hold on
            end
            errorb(1:Cols(M),nanmean(M), Sem(M));

        otherwise
            error('wrong type of plot')
    end
    hold on
    axis tight
    set(gca,'XTickLabel',xlab)
    set(gca,'XTickLabelRotation',45)
    title(reg)
    
    a = axis;
    a(1) = 0.4;
    if ~isempty(yrng)
        a(3:4) = yrng;
    end
    axis(a);
    plot(a(1:2),[0 0],':','LineWIdth', 3)
    
    
    if iReg == 1
        ylabel(ylab)
        
    else
        set(gca,'YTickLabel','')
    end
    pubify_figure_axis
end
if isempty(yrng)
    equalize_y_axes(h);
end

if make_sample
    % make a sample plot
    [p,n] = fileparts(which(mfilename));
    saveas(gcf,fullfile(p,[n '.png']))
end
