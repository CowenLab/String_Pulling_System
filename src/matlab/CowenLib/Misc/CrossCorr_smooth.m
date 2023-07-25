function [CC, x, CI95, CCbinned] = CrossCorr_smooth(t1,t2,binsize,maxlag,smthwinsize,jitter_sd)
% function [CC, x, CI95, CI95sd] = CrossCorr_smooth(t1,t2,binsize,maxlag,smthwinsize)
if nargin < 5
    smthwinsize = [];
end
if nargin < 6
    %     jitter_sd = []; % for shuffle confidence intervals.
    jitter_sd = binsize*maxlag*2; % add jitter on the order of the bandwidth of interest of the acorr.
end
CC = nan(1,maxlag*2+1);
x = nan(1,maxlag*2+1);
CI95 = nan(2,maxlag*2+1);
if length(t1) < 30
    % Don't bother for very small numbers of spikes - as it's meaningless.
    disp(['Not enough spikes in ' mfilename]);
    return
end

if 0
    binsize = 5;
    maxlag = 100;
    smthwinsize = 20; % this imposes a baseline correlation that is HIGH - about .5.
    % Why? I don't know.
    t1 = cumsum(100*rand(1000,1));
    t2 = cumsum(100*rand(1000,1));
end
at = [t1(:);t2(:)];

% rng = [min(at) max(at)];

edges = min(at):binsize:max(at);

t1c = histcounts(t1,edges);

if isempty(t2)
    % Autocorr assumed if no val for t2
    AUTOCORR = true;
    t2 = t1;
    t2c = t1c;
else
    AUTOCORR = false;
    
    t2c = histcounts(t2,edges);
end

if isempty(smthwinsize)
    t1c = t1c - mean(t1c);
    t2c = t2c - mean(t2c);
    [CC,lags] = xcorr(t1c,t2c,maxlag,'coeff');
else
    han = hanning(smthwinsize)';
    han = han/sum(han);
    c1 = conv(t1c, han);
    c1 = c1-mean(c1); % need to subtract mean for this to not have an artifactually high CC - not 100% sure why.
    if AUTOCORR
        c2 = c1;
    else
        c2 = conv(t2c, han);
        c2 = c2-mean(c2);
    end
    [CC,lags] = xcorr(c1,c2,maxlag,'coeff');
end

if AUTOCORR
    if isempty(smthwinsize)
        BIX = lags ==0;
    else
        BIX = abs(lags) < smthwinsize;
    end
    CC(BIX) = nan;
end

x = lags*binsize;

if nargout > 3
    [CCbinned,xccold] = CrossCorr(t1,t2,binsize,maxlag*2);
end
if nargout == 3 || nargout == 0
    % Shuffle
    nboot = 150;
    CCshuf = zeros(nboot,length(CC));
    for ii = 1:nboot
        sh = Shuffle_ISIs(t1,'no_replacement',jitter_sd);
        CCshuf(ii,:) = CrossCorr_smooth(sh,t2,binsize,maxlag,smthwinsize);
    end
    %     CI95 = prctile(CCshuf,[97.5 2.5]);
    CI95 = zeros(2,length(CC));
    CI95(1,:) = mean(CCshuf) - std(CCshuf)*1.96;
    CI95(2,:) = mean(CCshuf) + std(CCshuf)*1.96;
    % Do we really need to do this by col? Also means that I don't need to
    % shuffle as much. ANSWER: Yes we do - looking at data, there d
    CI95sd_all = [nanmean(CCshuf(:)) + nanstd(CCshuf(:))*1.96 ...
        nanmean(CCshuf(:)) - nanstd(CCshuf(:))*1.96];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % for testing...
    if nargout == 0
        [CCold,xccold] = CrossCorr(t1,t2,binsize,maxlag*2);
        IX = abs(xccold) < 3;
        CCold(IX) = nan;
        figure
        plot(x,CC,'k','LineWidth',2)
        hold on
        axis tight
        plot(x,CI95(1,:),'r')
        plot(x,CI95(2,:),'r')
        plot(x,mean(CCshuf),'c')
        plot_horiz_line_at_zero(CI95sd_all(1));
        plot_horiz_line_at_zero(CI95sd_all(2));
        pubify_figure_axis
        plot_vert_line_at_zero
        ylabel('r')
        yyaxis right
        plot(xccold,CCold,'g')
    end
end
