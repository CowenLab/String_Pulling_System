function [h,pvals,EFFECT_SIZE,allMnSPC] = PLOTSPEC_mean_power_by_fq_region_and_interval(...
    SPEC,...
    validIX,...
    regionID,...
    region_labels,...
    xlab,...
    ylab,...
    plot_type,...
    yrng,...
    offset,...
    clr, ...
    BASSPEC,...
    n_rows_cur_row)
% Restrict SPEC to the frequencies of interest before passing it into this
% function.
% 
% PLot the average response across trials.
% SPEC is a 4d matrix col 1 = time, col 2 = frequencies, col 3 = injection,
% col 4 = group.
% This asks the overall question - is activity greater than baseline?
%
if nargin < 9
    offset = 0;
end
if nargin < 10
    clr = [.5 .1 .5 ];
end
if nargin < 11
    BASSPEC = [];
end
if nargin < 12
    n_rows_cur_row = [1 1];
end
PLOT_DOTS = false;
Z_SCORE_IT = false;
do_vert = false;
plot_axis_lab = true;
plot_p_vals = false;
pvals = [];
error_bar_width = .6;
bar_width = .19;
x_expansion_factor = 0.02;
make_sample = false;
mk_size =4;
pvals = NaN(length(region_labels),size(SPEC,2));
if size(SPEC,2) ~= length(xlab)
    error('Number of frequencies in SPEC and xlab not consistent')
end

for iReg = 1:length(region_labels)
    reg = region_labels{iReg};
    IX =  validIX(:,1) & strcmp(regionID, reg)';
    
    n(iReg) = sum(IX);
    SPECreg = SPEC(:,:,:,IX);
    %     SPECreg = trimmean(SPECreg,10,1); % squeez across all time
    SPECreg = nanmean(SPECreg,1); % squeez across all time
    %     if ~isempty(BASSPEC)
    %         % Subtract baseline
    %         BASEreg = BASSPEC(:,:,:,IX);
    %         BASEreg = (trimmean(BASEreg,10,1)); % squeez across all time
    %         SPECreg = SPECreg - BASEreg;
    %     end
    %     if Z_SCORE_IT
    %         % Z score across injections to allow for examination of increases or
    %         % decreases.
    %         SPECregZ = NaN(size(SPECreg));
    %         for iSes = 1:size(SPECreg,4)
    %             SPECregZ(:,:,:,iSes) = Z_scores(SPECreg(:,:,:,iSes)')';
    %         end
    %         SPECreg = SPECregZ;
    %     end
    
    MnSPC = squeeze(nanmean(SPECreg,3))'; % Average across epochs.
    %     MnSPC = squeeze(SPECreg(:,5,:))'; % Average across epochs.
    M = MnSPC;
    allMnSPC{iReg} = MnSPC;
    %     M = nanmean(MnSPC,3)';
    %         [pvals(iReg,:)] = signrank_matrix(M);
    [pvals(iReg,:)]           = bonf_holm(ttest_matrix(M));
    [panov(iReg),tbl,stats] = anova1(M,[],  'off'); % Am I comparing bewteen groups? Just seeing if different from zero right now - probably bonferroni.
    COMPS(iReg,:,:)           = multcompare(stats,[],'off');
    EFFECT_SIZE(iReg,:)     = mean(M)./std(M);
    %     h(iReg) = subplot_ij(1,length(region_labels),1,iReg,x_expansion_factor,[]);
    if do_vert
        ix_subplot = iReg + (n_rows_cur_row(1)-1)*length(region_labels) ;
        h(iReg) = subplot(length(region_labels),n_rows_cur_row(1),ix_subplot);
    else
        ix_subplot = iReg + (n_rows_cur_row(2)-1)*length(region_labels) ;

        h(iReg) = subplot(n_rows_cur_row(1),length(region_labels),ix_subplot);
    end
    
    switch plot_type
        case 'boxplot'
            boxplot(M,'PlotStyle','compact');
        case 'errorbar'
            x = (1:Cols(M))+offset;
            if PLOT_DOTS
                for ii = 1:Rows(M)
                    plot(x,M(ii,:),'o','MarkerSize',mk_size,'Color',[.6 .6 .6],'MarkerFaceColor',clr*.85)
                    hold on
                end
            end
            mn = nanmean(M); se = Sem(M);
            % Use this for bar plots
            cc = clr*1.1;             cc(cc>1) = 1;
            bar(x,mn,bar_width,'FaceColor',cc,'EdgeColor',clr*.8)
            %             stem(x,mn,'filled','Color',clr,'MarkerSize',4)
            hold on
            hh = errorb(x,mn, se,'barwidth',error_bar_width);
            set(hh,'Color',[0 0 0])
            ix = find(pvals(iReg,:) < 0.05);
            a = axis;
            rng = a(4)-a(3);
            if plot_p_vals
                for ii = 1:length(ix)
                    text(x(ix(ii)),double(mn(ix(ii)) + se((ix(ii)))) + rng*.05,'*','FontSize',32, 'Color',clr,'HorizontalAlignment','center')
                end
            end
        otherwise
            error('wrong type of plot')
    end
    hold on
    axis tight
    if plot_axis_lab
        if  do_vert
            if  iReg == length(region_labels)
                set(gca,'XTickLabel',xlab)
%                 set(gca,'XTickLabelRotation',45)
            else
                set(gca,'XTickLabel','')
            end
            ylabel(ylab)
            
        else
            set(gca,'XTickLabel',xlab)
%             set(gca,'XTickLabelRotation',45)
            if iReg == 1
                ylabel(ylab)
                
            else
                set(gca,'YTickLabel','')
            end
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
