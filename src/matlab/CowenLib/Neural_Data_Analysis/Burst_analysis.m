function BRST = Burst_analysis(t_msec,burst_detect_method)
% Cotterill, E., & Eglen, S. J. (2019). Burst Detection Methods. Advances in Neurobiology, 22, 185–206. https://doi.org/10.1007/978-3-030-11135-9_8
if nargin < 2
    burst_detect_method = 'LogISIPasquale'; %GraceAndBunny
    %     burst_detect_method = 'GraceAndBunny'; %GraceAndBunny
end

BRST.Method = burst_detect_method;
BRST.MinSpikesPerBurst = 3; % from Cotterill...
BRST.MinBurstISIms = 3;
BRST.MaxBurstISIms = 200; % Bigger than this and it really can't be a burst.
BRST.BurstThreshMsec = [];
BRST.BurstDursMsec = [];
BRST.nPerBurst = [];

UPLIM_MS = 4000;
binsize_log10_ms = 0.1;

dt = diff(t_msec);

[BRST.HistISI, BRST.HistISI_logms_x] = histcounts(log10(dt),0:binsize_log10_ms:log10(UPLIM_MS)); % Parameters from Pasquale
x_log_ctrs = BRST.HistISI_logms_x(1:end-1) + diff(BRST.HistISI_logms_x)/2;
x_ms = 10.^x_log_ctrs;
BRST.HistISI_ctrs_ms = x_ms;

Hsmth = sgolayfilt(BRST.HistISI,3,9); % Actually pasquale uses a loewess filter but not sure this would do any better. Could try.
Hsmth(Hsmth < 0) = 0;
% HsmthL = loess(1:length(BRST.HistISI), BRST.HistISI,1:length(BRST.HistISI),.5,2); % Actually pasquale uses a loewess filter but not sure this would do any better. Could try.

th = max(Hsmth)/5;
IXmax = islocalmax(Hsmth) & Hsmth > th;
IXmin = islocalmin(Hsmth);

IXmax([1 end]) = 0; % don't allow peaks at the start or end.
IXmin([1 end]) = 0; % don't allow peaks at the start or end.

BRST.PeakISIs = x_ms(IXmax);
BRST.PeakISICounts = Hsmth(IXmax);
BRST.TroughISIs = x_ms(IXmin);
BRST.TroughISICounts = Hsmth(IXmin);
BRST.PeakRatesHz = 1000./BRST.PeakISIs;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
% HistISI(t_msec*10)
% hold on
% plot(x_ms,BRST.HistISI)
% set(gca,'XScale','log')
% hold on
% plot(x_ms,Hsmth)
% plot_vert_line_at_zero(BRST.PeakISIs,[],'b')
% plot_vert_line_at_zero(BRST.TroughISIs,[],'r')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot(x_log_ctrs,HsmthL)

% Identify bursts in the data...


% There are many burst detection approaches...
%Cotterill, E., & Eglen, S. J. (2019). Burst Detection Methods. Advances in Neurobiology, 22, 185–206. https://doi.org/10.1007/978-3-030-11135-9_8
% In the implementation of each method, the minimum number of
% spikes in a burst was set to three
switch burst_detect_method
    % Ordered by preference - or at least ratings in the Cotterill paper.
    case 'LogISIPasquale' %LogISI method (Pasquale et al. 2010).
        % this method seems to kill too many good bursts.. I tried
        % Pasquale's code - not really happy wiht it but needs some more
        % testing.
        BRST.MinPeakMs = 150;
        BRST.maxISImaxTh = 1000;
        BRST.VoidThresh = 0.7;
        if 0
            new_ts_ms = round(t_msec*1000);
            sp = sparse(1,new_ts_ms,1);
            sf = 1e6;
            
            [ISImax, pks, flags] = calcISImax(x_log_ctrs, Hsmth, 2,  BRST.VoidThresh,  BRST.MinPeakMs)
            %         [ISImax, pks, flags] = calcISImax(x_ms, Hsmth, 2,  BRST.VoidThresh,  BRST.MinPeakMs)
            % %
            if ~isempty(ISImax)
                [burstTrain, burstEventTrain] = burstDetectionPasquale(sp, ...
                    ISImax, flags, BRST.MinPeakMs, BRST.maxISImaxTh, sf, BRST.MinBurstISIms)
            end
        end
        % %
        IX = BRST.PeakISIs <= BRST.MinPeakMs & BRST.PeakISICounts > 1;
        GIX = false;
        if any(IX)
            GIX = IX & BRST.PeakISICounts == max(BRST.PeakISICounts(IX));
        end
        if any(GIX)
            pk1_ix = find(GIX);
            pk1_ix = pk1_ix(1);
            pk1_ISI = BRST.PeakISIs(pk1_ix);
            pk1_count = BRST.PeakISICounts(pk1_ix);
            other_peaks_ix = find(BRST.PeakISIs > pk1_ISI);
            void = zeros(1,length(other_peaks_ix));
            % Get rid of bad peaks...
            for iP = 1:length(other_peaks_ix)
                minval = min(Hsmth(pk1_ix+1:other_peaks_ix(iP)));
                pk2_count = BRST.PeakISICounts(other_peaks_ix(iP));
                void(iP) = 1-(minval/sqrt(pk1_count*pk2_count));
            end
            if any(void >= BRST.VoidThresh)
                [~,mxix] = max(void);
                pk2_ISI = BRST.PeakISIs(other_peaks_ix(mxix));
                XIX = x_ms > pk1_ISI & x_ms < pk2_ISI;
                IX = min(Hsmth(XIX)) == Hsmth & XIX;
                ix = find(IX);
                BRST.BurstThreshMsec = x_ms(ix(1));
                BRST.pk1_ISI = pk1_ISI;
                BRST.pk2_ISI = pk2_ISI;
            end
            
        end
    case 'CMA'
        % CMA
        csma = cumsum(Hsmth,'omitnan')./(1:length(Hsmth));
        [pk,loc] = findpeaks(csma);
        if ~isempty(pk)
            [pk, ix] = max(pk);
            loc = loc(ix);
            ix = find(csma>(pk*0.9) & (1:length(csma))>loc & x_ms> BRST.MinBurstISIms);
            if ~isempty(ix)
                BRST.BurstThreshMsec = x_ms(ix(1));
            end
        end
    case 'GraceAndBunny'
        % for dopamine neurons
        %          two spikes with an inter-spike interval (ISI) less than
        %          < 80 ms was designated as a burst onset and two spikes
        %          with an ISI of > 160 ms was designated as a burst
        %          termination.
        BRST.BurstThreshMsec = 80;
        BRST.SecondBurstThreshMsec = 160;
        
    case 'LogISICowen' %LogISI method but simple - maybe less robust?
        % LogISI. Simpler than above but perhaps more
        burst_th_ix = find(islocalmin(Hsmth))+1;
        burst_th_ix(x_ms(burst_th_ix) < BRST.MinBurstISIms) = []; % a burst threshold clearly has to be > BRST.MinBurstISIms
        if ~isempty(burst_th_ix)
            burst_th_ix = burst_th_ix(1);
            BRST.BurstThreshMsec = x_ms(burst_th_ix);
        end
        
    case 'ksdensity' % Cowen (like logisi but with a ks smoothed ISI histogram).
        % KSdensity. Assumes a minima  - but there might not be
        [BRST.HistISIks, BRST.HistISIks_logms_x] = ksdensity(log10(dt));
        x_log_ks_ctrs = BRST.HistISIks_logms_x + median(diff(BRST.HistISIks_logms_x))/2;
        x_ks_ms = 10.^x_log_ks_ctrs;
        GIX = x_ks_ms > BRST.MinBurstISIms & x_ks_ms < BRST.MaxBurstISIms;
        goodpeaks_ix = find(localmax(BRST.HistISIks) &  GIX);
        if ~isempty(goodpeaks_ix)
            ix = find(islocalmin(BRST.HistISIks));
            ix(ix < goodpeaks_ix) = []; % get rid of stuff before the first good peak.
            BRST.BurstThreshMsec = x_ks_ms(ix(1)); % First local min after the peak.
        end
        %     case 'asfMaxInterval' % Neural Explorer method
        %             Scan the spike train until an interspike interval is found that is less than or equal to Max. Interval
        % .
        % While the interspike intervals are less than Max. End Interval, they are included in the burst.
        % If the interspike interval is more than Max. End Interval, the burst ends.
        % Merge all the bursts that are less than Min. Interval Between Bursts apart.
        % Remove the bursts that have duration less than Min. Duration of Burst or have fewer spikes
        % than Min. Number of Spikes.
        
        
        
    otherwise
        error('incorrect type')
end
if ~isempty(BRST.BurstThreshMsec) && BRST.BurstThreshMsec < BRST.MaxBurstISIms
    switch burst_detect_method
        case 'GraceAndBunny'
            [BRST.FirstInBurstMsec,BRST.BurstDursMsec,BRST.nPerBurst] = Burst_detector(t_msec, BRST.BurstThreshMsec, BRST.MinSpikesPerBurst, BRST.SecondBurstThreshMsec);
        otherwise
            [BRST.FirstInBurstMsec,BRST.BurstDursMsec,BRST.nPerBurst] = Burst_detector(t_msec, BRST.BurstThreshMsec, BRST.MinSpikesPerBurst);
    end
    BRST.PortionSpikesInBurst = sum(BRST.nPerBurst)/length(t_msec);
    BRST.MeanBurstDurationMsec = mean(BRST.BurstDursMsec);
else
    %     disp('no burst thresh determined')
    BRST.BurstThreshMsec = [];
    return
end
%%
if nargout == 0
    figure
    subplot(2,3,1)
    plot(x_ms,BRST.HistISI);
    %     set(gca,'XTickLAbel',round(10.^BRST.HistISI_logms_x(1:end-1))))
    set(gca,'XScale','log')
    plot_vert_line_at_zero(BRST.BurstThreshMsec)
    % yyaxis right
    % plot(10.^BRST.HistISIks_logms_x,BRST.HistISIks);
    xlabel('log ISI ms')
    title(burst_detect_method)
    subplot(2,3,2)
    histogram(log10(diff(BRST.FirstInBurstMsec)),100)
    title(sprintf('th %f ms',BRST.BurstThreshMsec))
    subplot(2,3,3)
    [SS.AutoCorr, SS.Autocorr_x_ms] = AutoCorr(BRST.FirstInBurstMsec,2,200);
    plot(SS.Autocorr_x_ms,SS.AutoCorr);
    
    subplot(2,3,4:6)
    plot(t_msec/1000,ones(size(t_msec)),'k.')
    hold on
    plot(BRST.FirstInBurstMsec/1000,ones(size(BRST.FirstInBurstMsec)),'g>')
    plot(BRST.FirstInBurstMsec/1000 + BRST.BurstDursMsec/1000,ones(size(BRST.FirstInBurstMsec)),'r<')
    xlabel('s')
end