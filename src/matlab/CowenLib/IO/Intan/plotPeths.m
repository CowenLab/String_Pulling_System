function plotPeths(t_usec,ET,SAVE_PATH)
h = figure('units','normalized','outerposition',[0 0 1 1]);
xlabel('Cell Number')
hold on
N = length(t_usec);
for iCell = 1:N
    for iSub = 1:N
        hold on
        if iCell == iSub
            [B,C] = AutoCorr(t_usec{iSub}/100,1.5,30);
            subplot(N,N,((iCell-1)*8)+iSub)
            bar(C,B)
            xlabel(sprintf('Cell %d', iCell))
        else
            [bins,PETHdata] = PETHFR2(t_usec{iCell}/100000,t_usec{iSub}/100000,'binsize',0.04,'timerange',[-1 1],'plotpeth',0);
            subplot(N,N,((iCell-1)*8)+iSub)
            bar(bins, PETHdata, 'k');
            %         set(gca, 'xlim', timeRange)
            ax = axis;line([0 0], [ax(3) ax(4)],'Color','k')
            hold on
        end
    end
end

hcount = 50;
%save dat figure to it's place
    saveas(gcf,['.\Validation_Figures\' num2str(SAVE_PATH) '\PETH_AutoCorrelelograms' '_' num2str(hcount)],'png')
    close
    hcount = hcount + 1;

h2 = figure('units','normalized','outerposition',[0 0 1 1]);
for iCell = 1:N
    
    [bins,PETHdata] = PETHFR2(ET{1}.UpTransitions_usec/100000,t_usec{iCell}/100000,'binsize',0.04,'timerange',[-1 1],'plotpeth',0);
    subplot(ceil(sqrt(N)),ceil(sqrt(N)),iCell)
    bar(bins,PETHdata,'k');
    xlabel(sprintf('Cell %d, time(s)', iCell))
    ylabel('Firing rate')
    ax = axis;line([0 0], [ax(3) ax(4)],'Color','k')
     
end
    h2count = 150;
    %save dat figure to it's place
    saveas(gcf,['.\Validation_Figures\' num2str(SAVE_PATH) '\PETH_AutoCorrelelograms' '_' num2str(h2count)],'png')
    close
    h2count = h2count + 1;