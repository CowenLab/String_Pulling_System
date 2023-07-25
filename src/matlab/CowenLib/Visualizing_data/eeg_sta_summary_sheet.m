function h = eeg_sta_summary_sheet(t, eeg_files, sFreq ,eeg_names, eeg_interval_msec, wv, title_str)
% Shows the spike triggered average of EEG to events passed in.
% TIMES ARE PRESUMED TO BE IN .1 msec
if length(t) > 600
    % subsample
    r =randperm(length(t));
    t = unique(t(r(1:500)));
    disp('Subsampled')
end
clf
nFiles = length(eeg_files);
for iP = 1:nFiles
    
    [M, x_axis,fh,OUT] = PETH_EEG(eeg_files{iP}, sFreq ,t/10000, eeg_interval_msec(1)/1000, eeg_interval_msec(2)/1000);
    % subplot_ij(nFiles,2,iP,1)
    h(iP) = subplot(nFiles,1,iP)
    plot(x_axis,mean(M),'k')
    hold on
    plot(x_axis,mean(M) + Sem(M),'r:')
    plot(x_axis,mean(M) - Sem(M),'r:')
    plot(x_axis,median(M),'b')
    axis tight
    set(gca,'FontSize',7);
    [p n e] = fileparts(eeg_files{iP});
    if iP ==1
        title([title_str ' ' eeg_names{iP} ' ' n])
        a = axes('position',[.67 .85 .25 .15]);
        axes(a); plot(wv')
        axis off;
    else
        title([eeg_names{iP} ' ' n])
    end
    
    if iP == nFiles
        xlabel('Time (sec), bk = mean, bl = median')
        ylabel(OUT.ylabel_str)
    end
end


