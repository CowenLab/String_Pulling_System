function [h,R,Rse,OUT] = PLOTSPEC_spectrogram_by_region_and_event(SPEC,x_time,validIX,regionID,region_labels,plot_type, xlab,ylab,legend_txt,plot_error_bars,clrs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Restrict SPEC to the frequencies of interest before passing it into this
% function.
% ASSUMES TIME IS IN MINUTESs
% PLot the average response across trials.
% SPEC is a 4d matrix col 1 = time, col 2 = frequencies, col 3 = injection,
% col 4 = group.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 0
    % Load and show a figure of how this plot should look
    [p,n] = fileparts(which(mfilename));
    try
        image(imread(fullfile(p,[n '.png'])))
    catch
        error('Could not load or find the image for this function')
    end
    return
end

make_sample = true;
PLOT_HORIZ_LINE = false;
horz_max = [];
f1 = 10; 
f2 = 8; 
Lw = 2; % font sizes

if nargin < 10
    plot_error_bars = false;
end
if nargin < 11
    clrs = lines(size(SPEC,2));
end

x_expansion_factor = 0.05;

% AFTIX = x_time > 2 & x_time < 20;
%      AFTIX = x_time > 92 & x_time < 110;
AFTIX = x_time > 2 & x_time < 110;
BEFIX = x_time > -32 & x_time < -2;

R  = [];
Rse = [];
h = []; hh = [];
cnt =1;
for iReg = 1:length(region_labels)
    reg = region_labels{iReg};
    IX =  validIX & strcmp(regionID,reg)'; 
    SPECreg = SPEC(:,:,:,IX);
    % Compute the correlation bewteen each combination...
    tmpR = [];
    nInj = size(SPECreg,3);

    for iInj = 1:nInj 
        for iSes = 1:size(SPECreg,4)
             tmpR(:,:,iSes) = corrcoef(SPECreg(:,:,iInj,iSes));
        end
        R{iReg}(:,:,iInj) = nanmean(tmpR,3);
        Rse{iReg}(:,:,iInj) = Sem(tmpR,3);
    end


%     size(SPECreg)
    MnSPC = nanmean(SPECreg,4);
    SESPC = Sem(SPECreg,4);
    
    themeanbef = squeeze(trimmean(SPECreg(BEFIX,:,1,:),10,1));
%     themedianbef = squeeze(nanmedian(SPECreg(BEFIX,:,:,:),1));
       
    thesum = squeeze(nansum(SPECreg(AFTIX,:,:,:),1));
%     themean = squeeze(nanmean(SPECreg(AFTIX,:,:,:),1));
    themean = squeeze(trimmean(SPECreg(AFTIX,:,:,:),10,1));
    themedian = squeeze(nanmedian(SPECreg(AFTIX,:,:,:),1));
    themax = squeeze(nanmax(SPECreg(AFTIX,:,:,:),[],1));
 
    themean(:,1,:) = squeeze(themean(:,1,:)) -themeanbef;
    themean(:,2,:) = squeeze(themean(:,2,:)) -themeanbef;
    
    OUT.mean_pow_to_base1{iReg} = squeeze(themean(:,1,:)); %- themeanbef(1,1,:))';
    OUT.mean_pow_to_base2{iReg} = squeeze(themean(:,2,:)); %- themeanbef(1,1,:))';
    
    
    
    OUT.sumdiff{iReg} = squeeze(thesum(:,2,:) - thesum(:,1,:))';
    OUT.meandiff{iReg} = squeeze(themean(:,2,:) - themean(:,1,:))';
    OUT.mediandiff{iReg} = squeeze(themedian(:,2,:) - themedian(:,1,:))';
    OUT.maxdiff{iReg} = squeeze(themax(:,2,:) - themax(:,1,:))';
%     figure
%     Error_bars(OUT.sumdiff{iReg})
%     figure
%     Error_bars(OUT.maxdiff{iReg})
    OUT.sumdiff_p{iReg}  = ttest_pval(OUT.sumdiff{iReg});
    OUT.meandiff_p{iReg}  = ttest_pval(OUT.meandiff{iReg});
    OUT.mediandiff_p{iReg}  = ttest_pval(OUT.mediandiff{iReg});
    OUT.maxdiff_p{iReg}  = ttest_pval(OUT.maxdiff{iReg});
    
    for iInj = 1:nInj 
        M = squeeze(MnSPC(:,:,iInj));
        SE = squeeze(SESPC(:,:,iInj));
       
        
        switch plot_type
            case 'imagesc'
                v = iInj + (iReg-1)*nInj ;
%                 h(cnt) = subplot_ij(length(region_labels),size(MnSPC,3),iReg,iInj,x_expansion_factor,x_expansion_factor);
                h(cnt) = subplot(length(region_labels),size(MnSPC,3),v);
                if iscell(legend_txt)
                    imagesc(x_time,[],M')
                else
                    imagesc(x_time,legend_txt,M')
                end
                hold on
                axis xy
                a = axis;
                plot([0 0 ],a(3:4),'w','LineWidth',3)
                plot([0 0 ],a(3:4),'k:','LineWidth',3)
                %      colormap(inferno)
                %      colormap(viridis)
                colormap(jet)
                if iInj > 1
                    set(gca,'YTickLabel','')
                else
                    if iscell(legend_txt)
                        set(gca,'YTick',1:length(legend_txt))
                        set(gca,'YTickLabel',legend_txt)
                    end
                    
                    ylabel('Hz')
                end
                if iInj == 3
                    title(strrep(reg,'_',' to '))
                end
                if iReg < length(region_labels)
                    set(gca,'XTickLabel','')
                else
                    xlabel('min')
                end
                %         pubify_figure_axis
                if iReg == 1 && iInj == 5
                    colorbar_label(ylab);
                end
                pubify_figure_axis(f1, f2, Lw)
            case {'line' 'lines'}
                
                hh(cnt) = subplot_ij(length(region_labels),size(MnSPC,3),iReg,iInj,x_expansion_factor,x_expansion_factor);
                  
                pp = [];
                for iFq = 1:Cols(M)
                    pp(iFq) =  plot(x_time,M(:,iFq),'LineWidth',3,'Color',clrs(iFq,:));
                    hold on
%                     OUT.tau(cnt,:) = sum(M(AFTIX,iFq));
                    
                    if strcmp(plot_type,'lines')
                        C = squeeze(SPECreg(:,iFq,iInj,:));
                        plot(x_time,C,'Color',clrs(iFq,:));
                        plot_error_bars = false;
                    end
                    if plot_error_bars
                        plot(x_time,M(:,iFq) + SE(:,iFq),'LineWidth',1,'Color',clrs(iFq,:))
                        plot(x_time,M(:,iFq) - SE(:,iFq),'LineWidth',1,'Color',clrs(iFq,:))
                    end
                end
                if iReg == 1 && iInj == 1
                    if ~isempty(legend_txt)
                        legend(pp,legend_txt,'Autoupdate','off')
                        legend boxoff
                    end
                end
                axis tight
                if PLOT_HORIZ_LINE
                    for iFq = 1:Cols(M)
                        if iInj == 1
                            horz_max(iFq) = max(M(:,iFq));
                        end
                        plot_horiz_line_at_zero(horz_max(iFq),[],clrs(iFq,:));
                    end
                end
                pubify_figure_axis(f1, f2, Lw)

                a = axis;
                plot(a(1:2),[0 0],'k:','LineWidth',3)
                if iInj == 1
                    ylabel(ylab)
                else
                    set(gca,'YTickLabel','')
                end 
            case 'corr'
                hh(cnt) = subplot_ij(length(region_labels),size(MnSPC,3),iReg,iInj,x_expansion_factor,x_expansion_factor);
                step = 1;
                winsize_min = 20;
                
                dt_min = median(diff(x_time));
                winsize = round(winsize_min/dt_min);
                starts = 1:step:(size(SPECreg,1)-winsize);
                ends = starts + winsize;
                ix = find(triu(ones(size(SPECreg,2)),1) > 0);

                rr = nan(length(starts),length(ix),size(SPECreg,4));
                x_st =x_time(starts);
                x_ed =x_time(ends);
                x = (x_time(starts) + x_time(ends)) /2; % in centers.
                for iSes = 1:size(SPECreg,4)
                    S = squeeze(SPECreg(:,:,iInj,iSes));
                    ends(end) = Rows(S);
                    for iBin = 1:length(starts)
                        r = corrcoef_cowen(S(starts(iBin):ends(iBin),:),'pearsons');
                        if length(r) > 1
                            rr(iBin,:,iSes) = r(ix);
                        end
                    end
                end
                [i,j]=ind2sub(size(ones(Cols(S))),ix);
                labs = [];
                for ii = 1:length(i)
                    labs{ii} = [legend_txt{i(ii)} '-' legend_txt{j(ii)}]; 
                end
                %                 mn = mean(fisher_Z_score( rr),3);
                % subtract a baseline
%                                  rr = fisher_Z_score( rr);
                if iInj == 1
                    base_IX = x_ed<=-2;
                    base = nanmean(rr(base_IX,:,:),1);                   
                end
                rr = rr - repmat(base,size(rr,1),1,1);
                mn = nanmean(rr,3);
                se = Sem(rr,3);
                clrs = lines(Cols(mn));
                pp = [];
                for iFC = 1:Cols(mn)
                    pp(iFC) = plot(x,mn(:,iFC), 'LineWidth',4, 'Color', clrs(iFC,:));
                    hold on 
                    plot(x,mn(:,iFC) + se(:,iFC), 'Color', clrs(iFC,:))
                    plot(x, mn(:,iFC) - se(:,iFC), 'Color', clrs(iFC,:))
                end
                if iReg == 1 && iInj == 1
                    if ~isempty(labs)
                        legend(pp,labs,'Autoupdate','off')
                        legend boxoff
                    end
                end
                
                axis tight
                if iInj == 1
                    ylabel('r-baseline')
                else
                    set(gca,'YTickLabel','')
                end 
                a = axis;
                plot(a(1:2),[0 0],'k:','LineWidth',3)
                pubify_figure_axis
        end
        cnt = cnt + 1;
        %
        if iInj == floor(size(MnSPC,3)/2)+1;
            title(strrep(reg,'_',' to '))
        end
        if iReg == length(region_labels)
            xlabel(xlab)
        else
            set(gca,'XTickLabel','')
        end
    end
end

switch plot_type
    case 'imagesc'
        equalize_color_axes(h)
    case {'line','corr'}
        equalize_y_axes(hh)
        for ii = 1:length(hh)
            axes (hh(ii))
            plot_vert_line_at_zero
        end
        h = hh;
end

if make_sample
    % make a sample plot
    [p,n] = fileparts(which(mfilename));
    saveas(gcf,fullfile(p,[n '.png']))
end
