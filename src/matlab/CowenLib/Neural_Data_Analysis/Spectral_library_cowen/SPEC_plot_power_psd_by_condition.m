function [h]=SPEC_plot_power_psd_by_condition(SPEC,x_time,fq_labels,validIX,regionID,region_labels,plot_type, time_intervals_to_plot,ylab,ylim)
% Restrict SPEC to the frequencies of interest before passing it into this
% function.
% Presumes the data have been smoothed and baseline subtracted prior to
% being passed into this function.
%
% PLot the average response across trials.
% SPEC is a 4d matrix col 1 = time, col 2 = frequencies, col 3 = injection,
% col 4 = group.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 10
    ylim = [];
end
ROT = false;
sub_base = false;
plot_error_bars = true;
plot_line_at_zero = true;
x_expansion_factor = 0.02;
lns = lines(size(time_intervals_to_plot,1));
baseIX = x_time >= -20  & x_time < -2;
xintIX = false(Rows(time_intervals_to_plot),length(x_time));

for iInt = 1:Rows(time_intervals_to_plot)
    xintIX(iInt,:) = x_time >= time_intervals_to_plot(iInt,1) & x_time < time_intervals_to_plot(iInt,2);
end
SPEC = real(SPEC);

h = zeros(length(region_labels)-1,1);
for iReg = 1:length(region_labels)
    reg = region_labels{iReg};
    IX =  validIX & strcmp(regionID,reg)';
    sum(IX)
    if sum(IX) ==0 
        disp('no records for this category')
        continue
    end
    SPECreg = SPEC(:,:,:,IX);
    SPC_int_base= squeeze(trimmean(SPECreg(baseIX',:,1,:),10,1));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    MnSPC_int = [];SeSPC_int = [];SDSPC_int = [];
    for iInt = 1:Rows(time_intervals_to_plot)
        SPC_int{iInt} = squeeze(trimmean(SPECreg(xintIX(iInt,:)',:,1,:),10,1));
        if sub_base
            M =  SPC_int{iInt} - SPC_int_base;
        else
            M =  SPC_int{iInt} ;
        end
        M(isinf(M)) = nan;
        
        MnSPC_int(iInt,:) = nanmean(M,2)';
        SDSPC_int(iInt,:) = nanstd(M,[],2)';
        VARSPC_int(iInt,:) = nanvar(M,[],2)';
        
        SeSPC_int(iInt,:) = Sem(M,2);
    end
    
    CVSPC_int = SDSPC_int./MnSPC_int;
    
    CVSPC_int(abs(CVSPC_int) > 60) = nan;
    
    if ROT
        h(iReg) = subplot_ij(numel(region_labels),1,iReg,1,x_expansion_factor);
    else
        h(iReg) = subplot_ij(1,numel(region_labels),1,iReg,x_expansion_factor);
    end
    pp = [];
    switch plot_type
        case 'mean'
            for ii = 1:Rows(time_intervals_to_plot)
                if ROT
                    pp(ii) =  plot(MnSPC_int(ii,:),fq_labels,'LineWidth',2,'Color',lns(ii,:));
                    hold on
                    if plot_error_bars
                        plot(MnSPC_int(ii,:) + SeSPC_int(ii,:),fq_labels,'LineWidth',1,'Color',lns(ii,:))
                        plot(MnSPC_int(ii,:) - SeSPC_int(ii,:),fq_labels,'LineWidth',1,'Color',lns(ii,:))
                    end
                else
                    pp(ii) =  plot(fq_labels,MnSPC_int(ii,:),'LineWidth',2,'Color',lns(ii,:));
                    hold on
                    if plot_error_bars
                        plot(fq_labels,MnSPC_int(ii,:) + SeSPC_int(ii,:),'LineWidth',1,'Color',lns(ii,:))
                        plot(fq_labels,MnSPC_int(ii,:) - SeSPC_int(ii,:),'LineWidth',1,'Color',lns(ii,:))
                    end
                end
            end
            
        case 'CV'
            for ii = 1:Rows(time_intervals_to_plot)
                pp(ii) =  plot(fq_labels,CVSPC_int(ii,:),'LineWidth',2,'Color',lns(ii,:));
                hold on
            end
            
    end
    axis tight
    pubify_figure_axis
    
    if ROT
        ylabel('Hz')
        xlabel('Hz')
        
        if plot_line_at_zero
            plot_vert_line_at_zero()
        end
    else
        xlabel('Hz')
        
        if plot_line_at_zero
            
            plot_horiz_line_at_zero()
        end
    end
    
    
    if iReg == length(region_labels)
        leglab = [];
        for ii = 1:Rows(time_intervals_to_plot)
            leglab{ii} = sprintf('%d-%d',time_intervals_to_plot(ii,1),time_intervals_to_plot(ii,2));
        end
        legend(pp,leglab)
        legend boxoff
    end
    if iReg == 1
        ylabel(ylab)
    else
        set(gca,'YTickLabel','')
    end
    axis tight
    if ~isempty(ylim)
        set(gca,'YLim',ylim)
    end
    
    title(reg)
end
if isempty(ylim) && sum(h) > 0
    equalize_y_axes(h)
end





