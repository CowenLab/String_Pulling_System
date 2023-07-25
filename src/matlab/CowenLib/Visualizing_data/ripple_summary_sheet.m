function h=ripple_summary_sheet(t,rip_SE,peak_t,smooth_peak_t,before_after_t,binsize, units, wv)
%function h=ripple_summary_sheet(t,rip_SE,peak_t,smooth_peak_t,before_after_t,binsize, units,wv)% Produce a pretty plot of ripple triggered averages of spike information.
% TIMES ARE PRESUMED TO BE IN MSEC.
nbins = sum(before_after_t)/binsize;
% Get the aligned events first, then plot.
ONSET      = Align_on_Events(t, rip_SE(:,1), before_after_t(1),before_after_t(2));
OFFSET     = Align_on_Events(t, rip_SE(:,2), before_after_t(1),before_after_t(2));
RIPPEAK    = Align_on_Events(t, peak_t, before_after_t(1),before_after_t(2));
sRIPPEAK   = Align_on_Events(Shuffle_ISIs(t), peak_t, before_after_t(1),before_after_t(2));
SMOOTHPEAK = Align_on_Events(t, smooth_peak_t, before_after_t(1),before_after_t(2));
% Plot
if ~isempty(ONSET)
    h(1) = subplot(2,3,1);
    [h1,x] = hist(ONSET(:,1),nbins);
    plot(x,h1); xlabel(units); ylabel('count');
    title('Onset','FontSize',10)
    axis tight
end
if ~isempty(OFFSET)
    h(2) =  subplot(2,3,2);
    [h1,x] = hist(OFFSET(:,1),nbins);
    plot(x,h1); xlabel(units); ylabel('count');
    title('Offset','FontSize',10)
    axis tight
end
if ~isempty(SMOOTHPEAK)
     h(3) = subplot(2,3,3);
    [h1,x] = hist(SMOOTHPEAK(:,1),nbins);
    plot(x,h1); xlabel(units); ylabel('count');
    title('Smooth Peak','FontSize',10)
    axis tight
end
if ~isempty(RIPPEAK)
     h(4) = subplot(2,3,4);
    [h1,x] = hist(RIPPEAK(:,1),nbins);
    [h2,x] = hist(sRIPPEAK(:,1),nbins);
    plot(x,h2,'r',x,h1,'b'); xlabel(units); ylabel('count');
    title('Ripple Peak','FontSize',10)
    axis tight
end
%   OR

% AUTOCORR
if ~isempty(t)
    h(5) = subplot(2,3,5);
    % REQUIRES .1msec.
    %[Y, xdim]   = CrossCorr(t*10, t*10, binsize, nbins);
    [Y, xdim] = AutoCorr(t*10, binsize, round(nbins/2)); %*one sided.
    Y(find(Y==max(Y))) = nan;
    h = barp(xdim-.5*binsize,Y); % subtract .5binsize so that bins are centered on the xlabels
    set(h,'FaceColor','k')
    set(h,'EdgeColor','k')
    a = axis;
    a(3) = min(Y);
    axis(a)
    xlabel(units)
    ylabel('Rate (Hz)')
    title(['ACorr dt ' num2str(binsize) units],'FontSize',10);
end
% WAVEFORMS
h(6) = subplot(2,3,6);
plot(wv','LineWidth',4)
axis off


