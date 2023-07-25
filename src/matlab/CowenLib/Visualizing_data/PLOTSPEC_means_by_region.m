function PLOTSPEC_means_by_region(M,new_x_SPEC_min,fq_ix,fq_labels,validIX,region_labs,regs,plot_type,halfhan)
% PLot the average response across trials.
% M is a 4d matrix col 1 = time, col 2 = frequencies, col 3 = injection,
% col 4 = group.
make_sample = true;
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
BASELINE_IX = new_x_SPEC_min > -20 & new_x_SPEC_min < -2;

hh = [];
cnt = 1;

plot_error_bars = true;
for iReg = 1:length(regs)
    reg = regs{iReg};
    IX =  validIX & strcmp(region_labs,reg)'; tit = [ reg ' Ketamine'];
    %       IX =  ALL.SINFO_REG(:,3) == 2 & strcmp(ALL.SINFO_REG_STR,reg)'; tit = [ reg ' Control'];
    %     MnSPC = nanmean(ALL.S(:,:,1,IX),4);
    % Smooth this.
    MM = M(:,fq_ix,:,IX);
    MMs = NaN(size(MM));
    if ~isempty(halfhan)
        for ii = 1:size(MM,3)
            for jj = 1:size(MM,4)
                v = convn(squeeze(MM(:,:,ii,jj)),halfhan/sum(halfhan),'same');
                if 0
                    if ii == 1 % Just the first injection
                        mn = trimmean(v(BASELINE_IX,:),20,1);
                        sd = trimstd(v(BASELINE_IX,:),[10 90],1);
                        %                 mn = mean(v(BASELINE_IX,:),1);
                        %                 sd = std(v(BASELINE_IX,:),1);
                    end
                    v = v - repmat(mn,Rows(v),1);
                    v = v./repmat(sd,Rows(v),1);
                end
                MMs(:,:,ii,jj) = v;
            end
        end
        MM = MMs;
    end
    MnSPC = squeeze(nanmean(nanmean(MM,3),4));
    SESPC = squeeze(Sem(nanmean(MM,3),4));
    n_sessions = sum(IX);
    
    hh(cnt) = subplot_ij(length(regs),1,iReg,1,0,.02);
    cnt = cnt + 1;
    switch plot_type
        case 'imagesc'
            imagesc(new_x_SPEC_min,[],MnSPC')
            colormap(jet)
            caxis([ -.5 .5])
            ylabel('Hz')
            set(gca,'YTickLabel',fq_labels)
            
        case 'line'
            clrs = lines(Cols(MnSPC));
            for ii = 1:Cols(MnSPC)
                pp(ii) = plot(new_x_SPEC_min,MnSPC(:,ii),'LineWidth',3,'Color',clrs(ii,:));
                hold on
                if plot_error_bars
                    plot(new_x_SPEC_min,MnSPC(:,ii)'+ SESPC(:,ii)','LineWidth',1,'Color',clrs(ii,:))
                    plot(new_x_SPEC_min,MnSPC(:,ii)'- SESPC(:,ii)','LineWidth',1,'Color',clrs(ii,:))
                end
            end
            ylabel('Std')
            if iReg == 1
                legend(pp,fq_labels)
                legend boxoff
            end
    end
    axis tight
    hold on; axis xy;
    %     colormap(inferno)
    if iReg == length(regs)
        xlabel('min')
    else
        set(gca,'XTickLabel','')
    end
    
    if iReg == 1
        title([tit ' All Injections'])
        
        if strcmpi(plot_type,'imagesc')
            colorbar_label('std');
        end
    else
        title(reg)
    end
    pubify_figure_axis
end
equalize_axes(hh)
for ii = 1:length(hh)
    axes(hh(ii))
    a = axis;
    plot([0 0 ],a(3:4),'w','LineWidth',3)
    plot([0 0 ],a(3:4),'k:','LineWidth',3)
end

if make_sample
    % make a sample plot
    [p,n] = fileparts(which(mfilename));
    saveas(gcf,fullfile(p,[n '.png']))
end
