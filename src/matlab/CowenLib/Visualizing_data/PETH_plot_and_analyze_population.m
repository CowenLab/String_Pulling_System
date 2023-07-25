function INFO = PETH_plot_and_analyze_population(x,M,varargin)
x_units = 'ms';
PLOT_IT = true;
% PLOT_IX = true(size(x));
ANA_IX_BEF = x < 0;
ANA_IX_AFT = x > 0;
sort_type = {'peak' 'peak' 'peak' 'peak' 'peak' 'peak' 'peak' 'peak' 'peak' 'peak' 'peak' 'peak' 'peak' };
% bin_size = [];
% cmap_name = 'delta';
cmap = 'jet';
caxis_limits = [];
groups = ones(Rows(M),1); % you can have multiple groups and plot and act on these separately.
group_names = [];
title_str = '';
XLim = [x(1) x(end)];
clrs = lines(10);
waveforms = [];
PETH_subplot_size = 7;
SHOW_SIG = false;
p_thresh = 0.01;

Extract_varargin

plot_dims{1} = 1:PETH_subplot_size;
plot_dims{2} = (PETH_subplot_size+1):(PETH_subplot_size+3);

ANA_IX = ANA_IX_AFT | ANA_IX_BEF;
ix_x_is_zero = find(x == 0,1,'first');
gps = unique(groups);
%  pull out the correct groups.
Mall = [];
Mg = cell(length(gps),1);
for iG = 1:length(gps)
    IX = groups == gps(iG);
    INFO.ix{iG} = find(IX);
    TMP = M(IX,:);
    TMPana = M(IX,ANA_IX);
    if ~isempty(sort_type{iG})
        [~,v]= sort_matrix(TMPana,sort_type{iG});
        TMP = TMP(v(:,2),:);
        INFO.ix{iG} = INFO.ix{iG}(v(:,2)); % so that the sort order is preserved
    end
    Mg{iG} = TMP;
    Mg_ana = Mg{iG}(:,ANA_IX); 
    x_ana = x(ANA_IX);
    
    trial_marker(iG) = Rows(Mg{iG}) + Rows(Mall);
    aft_m_bef{iG} = nanmean(Mg{iG}(:,ANA_IX_AFT),2) - nanmean(Mg{iG}(:,ANA_IX_BEF),2);
    % Find peaks
    [~,loc] = max(Mg_ana,[],2);
    peak_offsets{iG} = x_ana(loc)'; % time relative to event where peak was.
    at_zero{iG} = Mg{iG}(:,ix_x_is_zero);
    Mall = [Mall;Mg{iG}];
    
    
    INFO.mnG(iG,:) = nanmean(Mg{iG},1);
    INFO.semG(iG,:) = Sem(Mg{iG},1);
    INFO.signrank_all_p(iG,:) = signrank_matrix(Mg{iG});
    INFO.signrank_peak_p(iG) = signrank(peak_offsets{iG});
    INFO.signrank_aft_m_bef_p(iG) = signrank(aft_m_bef{iG});
    INFO.signrank_is_zero_p(iG) = signrank(at_zero{iG});
    
end
trial_marker(end) = [];
INFO.aft_m_bef = aft_m_bef;
INFO.peak_offsets = peak_offsets;
INFO.at_zero = at_zero;
INFO.Mg = Mg;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot the results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if PLOT_IT
    max_subplot = plot_dims{end}(end);
    yvals = [1 trial_marker];
    figure
    subplot(max_subplot,1,plot_dims{1})
    imagesc(x, [],  Mall)
    if ~isempty(trial_marker)
        for iM = 1:(length(trial_marker))
            plot_horiz_line_at_zero(trial_marker(iM) + .5,3,'k','-')
            plot_horiz_line_at_zero(trial_marker(iM) + .5,3,'w')
            plot([XLim(1) XLim(1)], [trial_marker(iM)-.5 yvals(iM)],'Color',clrs(iM,:),'LineWidth',5)
        end
        plot([XLim(1) XLim(1)], [Rows(Mall) trial_marker(iM)+.5],'Color',clrs(iM+1,:),'LineWidth',5)
    end
    plot_vert_line_at_zero
    box off
    pubify_figure_axis
    set(gca,'XTickLabel','')
    % ylabel('Neuron ID')
    title(title_str)
    colorbar_label
    try
        colormap(cmap)
    catch
        cmocean(cmap) % I like delta or jet %  cmocean('thermal') % I like delta or jet%   colormap(redblue)
    end
    if ~isempty(caxis_limits)
        caxis(caxis_limits)
    end
    set(gca,'XLim',XLim)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    subplot(max_subplot,1,plot_dims{2})
    for ii = 1:length(Mg)
        plot_confidence_intervals(x, Mg{ii}, [], clrs(ii,:))
    end
    axis tight
    plot_vert_line_at_zero
    plot_horiz_line_at_zero(0,1.2,'k','-')
    plot_confidence_intervals(x, Mg{1}, [], clrs(1,:)) % work around to get it to look good.
    pubify_figure_axis
    if SHOW_SIG
        a = axis;
        for ii = 1:length(Mg)
            IX = INFO.signrank_all_p(ii,:) < p_thresh;
            if any(IX)
                plot(x(IX),a(4),'r*')
            end
        end
        title(sprintf('* = p < %0.4f',p_thresh),'FontSize',7)
    end
    
    xlabel(x_units)
    
    set(gca,'XLim',XLim)
    set(gcf,'Position',[586.6        117.8          412        709.6])
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % plot out the 
    figure
    subplot(2,2,1)
    histogram_cowen(peak_offsets,[],[],[],'pdf',false)
    plot_vert_line_at_zero
    title(sprintf('Peak to onset Pk p=%1.3f',INFO.signrank_peak_p),'FontSize',9)
    %     legend(group_names); legend boxoff
    xlabel('t of peak response')
    legend(group_names); legend boxoff
    pubify_figure_axis
    
    subplot(2,2,2)
    histogram_cowen(aft_m_bef,[],[],[],'pdf',false)
    plot_vert_line_at_zero
    title(sprintf('Mean: p=%1.3f',INFO.signrank_aft_m_bef_p),'FontSize',9)
    pubify_figure_axis

    xlabel('after-before frate')

    subplot(2,2,3)
    histogram_cowen(at_zero,[],[],[],'pdf',false)
    plot_vert_line_at_zero
    title(sprintf('Mean: p=%d',INFO.signrank_is_zero_p),'FontSize',9)
    xlabel('frate at t = 0')
    pubify_figure_axis

    subplot(2,2,4)
    vv = [sum(at_zero{1} < 0) sum(at_zero{1} > 0)];
    bar(vv)
    set(gca,'XTickLabel',{'<0','>0'})
    [p_bintest] = binomial_test_cowen(vv(1), sum(vv), 0.5);
    title(sprintf('bintest p = %d',p_bintest))
    pubify_figure_axis
    
    sgtitle(title_str)
    set(gcf,'Position',[336.2        153.8        921.6        673.6])
    
    
    
    
    %%%%%%%%
    if ~isempty(waveforms)
        % Construct waveform matrix.
        WV = [];
        for ii = 1:length(INFO.ix)
            WV = [WV; waveforms(INFO.ix{ii},:)];
        end
        figure
        subplot(3,1,1:2)
        imagesc(WV)
        if ~isempty(trial_marker)
            
            for iM = 1:(length(trial_marker))
                plot_horiz_line_at_zero(trial_marker(iM) + .5,3,'k','-')
                plot_horiz_line_at_zero(trial_marker(iM) + .5,3,'w')
                plot([1 1], [trial_marker(iM)-.5 yvals(iM)],'Color',clrs(iM,:),'LineWidth',5)
            end
            plot([1 1], [Rows(WV) trial_marker(iM)+.5],'Color',clrs(iM+1,:),'LineWidth',5)

        end
        title(title_str)
        pubify_figure_axis
        subplot(3,1,3)
        for ii = 1:length(INFO.ix)
            plot(waveforms(INFO.ix{ii},:)','Color',clrs(ii,:))
            hold on
        end
        for ii = 1:length(INFO.ix)
            plot(nanmean(waveforms(INFO.ix{ii},:)),'Color','k','LineWidth',4)
            plot(nanmean(waveforms(INFO.ix{ii},:)),'Color',clrs(ii,:),'LineWidth',2)
        end
        pubify_figure_axis

    end
end
