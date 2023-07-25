function [RF,RIPS] = Ripple_features(raw_filt_LFP, riptimes_usec)
%function [RF,RIPS] = Ripple_features(raw_filt_LFP, riptimes_usec)
% Generate some useful information about each ripple.
%
% INPUT:
%   raw_filt_LFP:
%    First col - timestamps in usec
%    Second col - raw ripple data.
%    Third col - filtered ripple data.
%
%  riptimes_usec_usec = the start and end times (usec) of each ripple
%
%  OUTPUT:
%  RF - ripple features - useful data about each ripple.
%  RIPS - the raw ripple waveforms.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
buf_sec = 0.05; % time around ripple to save.
peri_rip_baseline_sec = .5; % time before and after the ripple (buffer - for filtering).

% the use of structures is a great way to organize your data.
plot_it = false;
nRips = Rows(riptimes_usec);
RF.riptimes_usec = riptimes_usec;
RF.rip_times_p2p_usec = riptimes_usec*nan;

RF.PeakToPeak_Duration_ms = zeros(nRips,1)*nan;
RF.Std = zeros(nRips,1)*nan;
RF.Max = zeros(nRips,1)*nan;
RF.Min = zeros(nRips,1)*nan;
RF.InterPeakStd_msec = zeros(nRips,1)*nan;
RF.InterPeakMean_msec = zeros(nRips,1)*nan;
RF.InterPeakFano = zeros(nRips,1)*nan;
RF.MeanFiltEnergy = zeros(nRips,1)*nan;
RF.Mean = zeros(nRips,1)*nan;
RF.nPeaks = zeros(nRips,1)*nan;
RF.WithinRipMeanIntervalChangeMsec = zeros(nRips,1)*nan;
RF.WithinRipChangeRegressSlope = zeros(nRips,1)*nan;
RF.PeakRipDeflection= zeros(nRips,1)*nan;
RF.SampEntropy = zeros(nRips,1)*nan;

RF.EstRipFreq = zeros(nRips,1)*nan;
RF.PeakRipFreq = zeros(nRips,1)*nan;

RF.SpectPeakRipFreq = zeros(nRips,1)*nan;
RF.SpectPeakPow = zeros(nRips,1)*nan;
RF.SpectPeakTimeAssymetry = zeros(nRips,1)*nan;
RF.SpectHighGammaFreq = zeros(nRips,1)*nan;
RF.SpectHighGammaPow = zeros(nRips,1)*nan;
RF.SpectMinGammaFreq = zeros(nRips,1)*nan;
RF.SpectMinGammaPow = zeros(nRips,1)*nan;
RF.SpectRipToGamPow = zeros(nRips,1)*nan;
RF.SpectRipQualityRipToHGammaRatio = zeros(nRips,1)*nan;
RF.SpectPeakRipFreqStart= zeros(nRips,1)*nan;
RF.SpectPeakRipFreqEnd= zeros(nRips,1)*nan;
RF.SpectPeakRipFreqStartEndChange= zeros(nRips,1)*nan;
RF.SpectPeakRipPowStart= zeros(nRips,1)*nan;
RF.SpectPeakRipPowEnd= zeros(nRips,1)*nan;
RF.SpectPeakRipPowStartEndChange= zeros(nRips,1)*nan;

RF.TimeFromRestOnset_sec = zeros(nRips,1)*nan;
RF.PeakPowerTimes_usec = zeros(nRips,1)*nan;
RF.PeakPowerAssymetry = zeros(nRips,1)*nan;
RF.RipToGamPow= zeros(nRips,1)*nan;
RF.RipToHighPow= zeros(nRips,1)*nan;
RF.RipQualityRipToHGammaRatio = zeros(nRips,1)*nan;
RF.ProportionOfSaturatingPoints = zeros(nRips,1)*nan;
RF.MaxRipplePowerDb = zeros(nRips,1)*nan;
RF.MaxHighGammaPowerDb = zeros(nRips,1)*nan;
RF.RipplePowerDb10  = zeros(nRips,1)*nan;
RF.RipplePowerDb20  = zeros(nRips,1)*nan;
RF.RipplePowerDb40  = zeros(nRips,1)*nan;
RF.RipplePowerDb400  = zeros(nRips,1)*nan;
RF.Valid_Rip_Fq_Range_Hz = [85 240];
RF.PSD_Fqs = 80:2:310;
RF.PSD_bef_after_rip_Fqs = 2:1:240;
RF.RIP_IX = RF.PSD_Fqs>=140 & RF.PSD_Fqs<=240;
RF.GAM_IX = RF.PSD_Fqs>=80 & RF.PSD_Fqs<140;
RF.HIGH_IX = RF.PSD_Fqs>=280 ;
RF.PSD_Fqs_Db = zeros(nRips,length(RF.PSD_Fqs ))*nan;
%
% RF.Ripple_Fqs = 140:200;
% RF.Ripple_Fqs_Db = zeros(nRips,length(RF.Ripple_Fqs ))*nan;
% RF.High_Gamma_Fqs = [70:2:120];
% RF.High_Gamma_Fqs_Db = zeros(nRips,length(RF.High_Gamma_Fqs ))*nan;
% RF.Ultra_Ripple_Fqs = [ 240:20:500];
% RF.Ultra_Ripple_Fqs_Db =  zeros(nRips,length(RF.Ultra_Ripple_Fqs ))*nan;
% % RF.RipplePowerDbAll_Fqs = [70 85 110 140 155 170 185 300 400 500];
% RF.RipplePowerDbAll = zeros(nRips,length(RF.RipplePowerDbAll_Fqs ))*nan;
%
RIPS.FirstPeakInRip_usec = zeros(nRips,1)*nan;
RIPS.LastPeakInRip_usec  = zeros(nRips,1)*nan;
RIPS.Before_PSD = zeros(nRips,length(RF.PSD_bef_after_rip_Fqs),'single')*nan;
RIPS.After_PSD  = zeros(nRips,length(RF.PSD_bef_after_rip_Fqs),'single')*nan;
RIPS.raw_rips = cell(nRips,1);
RIPS.filt_rips = cell(nRips,1);
RIPS.x_msec = cell(nRips,1);
RIPS.PSD_bef_after_rip_Fqs = RF.PSD_bef_after_rip_Fqs;
if isempty( riptimes_usec)
    return
end
sFreq= 1e6/median(diff(raw_filt_LFP(:,1)));

% profile on
tmpWAVE = zeros(nRips,length(RF.PSD_Fqs));
st = binsearch_vector( raw_filt_LFP(:,1), riptimes_usec(:,1));
ed = binsearch_vector( floor(raw_filt_LFP(:,1)), floor(riptimes_usec(:,2)));
st_buffered = st - round(buf_sec*sFreq);
ed_buffered = ed + round(buf_sec*sFreq);
bef_rip_baseline_st_ed = [st_buffered(:) - round(peri_rip_baseline_sec*sFreq) st_buffered(:)] ;% this is baseline.aft
aft_rip_baseline_st_ed = [ed_buffered ed_buffered + round(peri_rip_baseline_sec*sFreq)];
if isempty(bef_rip_baseline_st_ed)
    return
end

BIX = bef_rip_baseline_st_ed(1) < 1 | aft_rip_baseline_st_ed(end) > Rows(raw_filt_LFP);


if any (BIX)
    %     st(BIX) = [];
    %     ed(BIX) = [];
    %     st_buffered(BIX) = [];
    %     ed_buffered(BIX) = [];
    %     bef_rip_baseline_st_ed(BIX) = [];
    %     aft_rip_baseline_st_ed(BIX) = [];
    disp('Found a ripple too early or too late - should have been deleted')
    return
end

for iRip = 1:nRips
    % Find the ripple that falls bewteen the identified range.
    rip_ix = st(iRip):ed(iRip);
    buf_rip_ix = st_buffered(iRip):ed_buffered(iRip);
    bef_base_ix = bef_rip_baseline_st_ed(iRip,1):bef_rip_baseline_st_ed(iRip,2);
    aft_base_ix = aft_rip_baseline_st_ed(iRip,1):aft_rip_baseline_st_ed(iRip,2);
    st_usec = riptimes_usec(iRip,1);
    ed_usec = riptimes_usec(iRip,2);
    
    %     st_usec_buffered = riptimes_usec(iRip,1) - 50000;
    %     ed_usec_buffered = riptimes_usec(iRip,2) + 50000;
    %
    %
    
    %     IX = raw_filt_LFP(:,1) >= st_usec & raw_filt_LFP(:,1) < ed_usec;
    
    %     IX_extended = raw_filt_LFP(:,1) >= st_usec - before_after_rip_usec & raw_filt_LFP(:,1) < ed_usec + before_after_rip_usec;
    %     IX_before = raw_filt_LFP(:,1) >= st_usec_buffered - post_rebound_before_after_rip_usec &  raw_filt_LFP(:,1) < st_usec_buffered;
    %     IX_after = raw_filt_LFP(:,1) < ed_usec_buffered + post_rebound_before_after_rip_usec &  raw_filt_LFP(:,1) > ed_usec_buffered;
    %     start_ix = find(IX,1,'first');
    x_usec   = raw_filt_LFP(rip_ix,1) - st_usec;
    raw_rip  = raw_filt_LFP(rip_ix,2);
    raw_rip_extended = raw_filt_LFP(buf_rip_ix,2);
    raw_rip_before = raw_filt_LFP(bef_base_ix,2);
    raw_rip_after = raw_filt_LFP(aft_base_ix,2);
    
    if length(raw_rip_before) > 100
        psd_before = pwelch(detrend(raw_rip_before),length(raw_rip_before),0, RF.PSD_bef_after_rip_Fqs, sFreq);
        RIPS.Before_PSD(iRip,:) = single(psd_before);
    end
    if length(raw_rip_after) > 100
        psd_after = pwelch(detrend(raw_rip_after),length(raw_rip_after),0, RF.PSD_bef_after_rip_Fqs, sFreq);
        RIPS.After_PSD(iRip,:) = single(psd_after);
    end
    %
    %     psd_before2 = pmtm(raw_rip_before,[], RF.PSD_bef_after_rip_Fqs, round(sFreq));
    %     psd_after2 = pmtm(raw_rip_after,[], RF.PSD_bef_after_rip_Fqs, round(sFreq));
    
    
    x_usec_extended  = raw_filt_LFP(buf_rip_ix,1) - st_usec; % Time zero is the start of the ripple.
    
    RIPS.x_msec{iRip} = single(x_usec_extended/1e3);
    RIPS.raw_rips{iRip} = raw_rip_extended;
    RIPS.filt_rips{iRip} = raw_filt_LFP(rip_ix,3);
    [~,maxix] = max(abs(RIPS.filt_rips{iRip}));
    
    whereitis = maxix/length(RIPS.filt_rips{iRip});
    peak_power_rip_times = st_usec + (ed_usec - st_usec).*whereitis;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Where the peak ripple power is...
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % UPSAMPLE: to get precise measures of the peak times.
    upsamp_x_usec = linspace(x_usec(1),x_usec(end),length(x_usec)*10); % UPSAMPLE
    upsampLFPrip = interp1(x_usec, RIPS.filt_rips{iRip},upsamp_x_usec,'spline');
    % find those peaks
    [pkfilt_ix,~,zerocross_ix] = Find_peaks_troughs_zeros(upsampLFPrip - mean(upsampLFPrip));
    % Inter-Peak variance...
    dfmsec = diff(upsamp_x_usec(pkfilt_ix))/1000;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % IPkI MEAN STD AND FANO
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Generate some features that may unravel the true nature of the
    % elusive ripple.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    RIPS.FirstPeakInRip_usec(iRip) = st_usec + upsamp_x_usec(pkfilt_ix(1));
    RIPS.LastPeakInRip_usec(iRip)  = st_usec + upsamp_x_usec(pkfilt_ix(end));
    
    % For validation - it does choose the peaks.
    %     IX = raw_filt_LFP(:,1) > RIPS.FirstPeakInRip_usec(iRip)-1e6 & raw_filt_LFP(:,1) < RIPS.LastPeakInRip_usec(iRip)+1e6;
    %     plot(raw_filt_LFP(IX,1), raw_filt_LFP(IX,2))
    %     hold on
    %     plot_markers_simple([RIPS.FirstPeakInRip_usec(iRip) RIPS.LastPeakInRip_usec(iRip)])
    %
    
    RF.rip_times_p2p_usec(iRip,1) = RIPS.FirstPeakInRip_usec(iRip);
    RF.rip_times_p2p_usec(iRip,2) = RIPS.LastPeakInRip_usec(iRip);
    RF.InterPeakStd_msec(iRip) = std(dfmsec);
    RF.InterPeakMean_msec(iRip) = mean(dfmsec);
    RF.InterPeakFano(iRip) = RF.InterPeakStd_msec(iRip)/RF.InterPeakMean_msec(iRip);
    RF.ProportionOfSaturatingPoints(iRip) = sum(abs(raw_rip)>2030 | abs( [nan ;diff(raw_rip)]) < 0.01) /length(raw_rip); % A quality measure.
    
    % This is slow but it matches the results of my peak-counting method
    % much better than pmtm.
    
    [SCImg, freq] = Spectrogram_ripple(detrend(raw_rip), sFreq, RF.PSD_Fqs,'wavelet');
    % limit this to the ripple range...
    %     RIX = freq > RF.Valid_Rip_Fq_Range_Hz(1) & freq < RF.Valid_Rip_Fq_Range_Hz(end);
    if ~isempty(SCImg)
        %     tic
        %     [~, ~, freq2, SCImg2] = Wavelet_ripple(raw_rip, sFreq, [20 450],0.2);
        %     toc
        % Time of peak power
        [RF.SpectPeakPow(iRip),tim_ix] = nanmax(nanmax(SCImg,[],1));
        mx_fq = SCImg(:,tim_ix);
        [~,fq_ix] = nanmax(mx_fq);
        mn_fq = nanmean(SCImg,2);
        RF.PSD_Fqs_Db(iRip,:)  = mx_fq;
        %     figure(22);clf;plot(RF.PSD_Fqs,mn_fq)
        %     mn_fq2 = pmtm(raw_rip,[],RF.PSD_Fqs,sFreq);
        %     figure(2);clf;plot(RF.PSD_Fqs,mn_fq2)
        
        % The spectrogram of the peak frequency.
        tmpWAVE(iRip,:) = mn_fq';
        % Find peak time.
        [~,cl] = size(SCImg);
        RF.SpectPeakTimeAssymetry(iRip) = (tim_ix/cl)-0.5;
        RF.SpectPeakRipFreq(iRip) = freq(fq_ix);
        
        % Peak start and end frequency and power.
        [mx,ix] = max(SCImg);
        RF.SpectPeakRipFreqStart(iRip) = freq(ix(1)); %Peak power at start of ripple
        RF.SpectPeakRipFreqEnd(iRip)   = freq(ix(end)); %Peak power at end of ripple
        RF.SpectPeakRipFreqStartEndChange(iRip) = RF.SpectPeakRipFreqEnd(iRip)-RF.SpectPeakRipFreqStart(iRip); %Peak power at start of ripple
        %
        RF.SpectPeakRipPowStart(iRip) = mx(1); %Peak power at start of ripple
        RF.SpectPeakRipPowEnd(iRip)   = mx(end); %Peak power at start of ripple
        RF.SpectPeakRipPowStartEndChange(iRip) =  mx(end)-mx(1); %Peak power at start of ripple
        
        fq_gam = freq(RF.GAM_IX);
        psd_gam = mx_fq(RF.GAM_IX);
        
        [mx,ix] = nanmax(psd_gam);
        
        RF.SpectHighGammaPow(iRip) = mx;
        RF.SpectHighGammaFreq(iRip) = fq_gam(ix);
        [mngam,ix] = min(psd_gam);
        RF.SpectMinGammaPow(iRip) = mngam;
        RF.SpectMinGammaFreq(iRip) = fq_gam(ix);
        RF.SpectRipToGamPow(iRip) = RF.SpectPeakPow(iRip)-RF.SpectMinGammaPow(iRip) ;
        RF.SpectRipQualityRipToHGammaRatio(iRip) = (RF.SpectPeakPow(iRip)+10)/(RF.SpectMinGammaPow(iRip)+10) ;% Had to add 10 because you get negative numbers sometimee - this is a crappy hack, there must be a better way.
        
        
        fq_rip = freq(RF.RIP_IX);
        psd_rip = mx_fq(RF.RIP_IX);
        [mxrip,ix] = nanmax(psd_rip);
        
        RF.PeakRipFreq(iRip) = fq_rip(ix);
        RF.MaxRipplePowerDb(iRip) = mxrip;
        RF.RipToGamPow(iRip) = mxrip - nanmin(psd_gam);
        
        RF.RipQualityRipToHGammaRatio(iRip) = (mxrip+20)/(min(psd_gam)+20);
        
        fq_high = freq(RF.HIGH_IX);
        psd_high = mx_fq(RF.HIGH_IX);
        
        RF.RipToHighPow(iRip) = mxrip - nanmax(psd_high);
        
        
        
        %     if 0
        %         subplot(2,1,1)
        %         plot(x_usec/1e3,raw_rip)
        %         title(num2str(RF.RipQualityRipToHGammaRatio(iRip)))
        %         subplot(2,1,2)
        %         pmtm(raw_rip,[],[50:10:400],sFreq);
        %     end
    end
    rip_dur_usec = upsamp_x_usec(pkfilt_ix(end)) - upsamp_x_usec(pkfilt_ix(1));
    
    RF.PeakPowerAssymetry(iRip) = whereitis-0.5; % location of peak power relative to the start of the ripple. 0 = right in the middle
    RF.PeakToPeak_Duration_ms(iRip) = rip_dur_usec/1e3;
    
    RF.EstRipFreq(iRip) = (length(zerocross_ix)-1)/(rip_dur_usec/1e6);
    
    RF.Std(iRip) = std(raw_rip); % Don't know what this means.
    RF.Max(iRip) = max(raw_rip);
    RF.Min(iRip) = min(raw_rip);
    RF.Mean(iRip) = mean(raw_rip);
    
    RF.PeakRipDeflection(iRip) =  max(abs(raw_rip));
    RF.nPeaks(iRip) =  length(pkfilt_ix);
    % is the ripple increasing or decreasing in fq?
    % need 2 diffs because you what to know how fast the INTERVALS between
    % ripples are changing.
    RF.WithinRipMeanIntervalChangeMsec(iRip) = mean(diff(diff(upsamp_x_usec(pkfilt_ix))/1e3)); % POSITIVE is a DECREASE in frequency (increase in inter-ripple duration)
    warning off
    b = regress(diff(upsamp_x_usec(pkfilt_ix))',[ones(length(pkfilt_ix)-1,1) (1:(length(pkfilt_ix)-1))']);
    warning on
    RF.WithinRipChangeRegressSlope(iRip) = b(2);
    % I comment SampleENtropy out sometimes as it is VERY slow relative to
    %     RF.SampEntropy(iRip) = SampEn(2,0.2*std(raw_rip),raw_rip);
    RF.MeanFiltEnergy(iRip) = mean(RIPS.filt_rips{iRip}.^2);
    %
    RF.TimeFromRestOnset_sec(iRip) = (riptimes_usec(iRip,1)- riptimes_usec(1))/1e6;
    RF.PeakPowerTimes_usec(iRip) = peak_power_rip_times;
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Plot (turn this off if you just want the feature data)
    if 0
        %         figure(1)
        %         % I tried the wavelet toolbox and I could not get it to work
        %         % correctly - very non-linear responses to frequency with the cwt
        %         % function - but it could be how I called it.
        %         spectrogram(raw_rip,[],[],[90:10:250],sFreq,'yaxis')
        %
        figure(2)
        clf
        subplot(3,1,1)
        plot(x_usec_extended/1e3, raw_rip_extended)
        
        axis tight
        plot_vert_line_at_zero
        subplot(3,1,2)
        
        x_msec = x_usec/1e3;
        upsamp_x_msec = upsamp_x_usec/1e3;
        plot(x_msec,raw_filt_LFP(IX,2))
        hold on
        plot(x_msec,raw_filt_LFP(IX,3),'r')
        plot(upsamp_x_msec(:),upsampLFPrip,'r')
        plot(upsamp_x_msec(pkfilt_ix),upsampLFPrip(pkfilt_ix),'g*')
        axis tight
        pubify_figure_axis
        xlabel('ms')
        subplot(3,1,3)
        pmtm(raw_rip_extended,[],[10 20 40 70 85 100 140 155 170 185 400 ],sFreq)
        pause
        clf
    end
end
% profile viewer

if plot_it
    %%
    load Session_Info
    S = Load_tfiles(ses.tfilefullnames);
    S = Restrict(S,RF.rip_times_p2p_usec(:,1)/100 - 50e4, RF.rip_times_p2p_usec(:,2)/100 + 50e4);
    for iRip = 1:4:length(RIPS.x_msec)
        rip_dur_ms = diff(RF.rip_times_p2p_usec(iRip,1:2))/1000;
        IX = RIPS.x_msec{iRip} >-50 & RIPS.x_msec{iRip} < (rip_dur_ms + 50);
        figure
        Plot_ripple(RIPS.x_msec{iRip}(IX),RIPS.raw_rips{iRip}(IX),sFreq,S,RF.rip_times_p2p_usec(iRip,1:2)/100);
        label_figure([mfilename ' ' ses.animal ' ' ses.name ])
        title([num2str(iRip) ' Qs ' num2str(RF.RipQualityRipToHGammaRatio(iRip)) ' Qp ' num2str(RF.RipToGamPow(iRip)) ])
    end
    %%
    V  =  RF.PSD_Fqs_Db;
    V = tmpWAVE;
    figure
    subplot(3,1,1)
    imagesc(RF.PSD_Fqs, [], V);
    subplot(3,1,2)
    imagesc(RF.PSD_Fqs, [], sort_matrix( V));
    subplot(3,1,3)
    plot_confidence_intervals(RF.PSD_Fqs,V)
    label_figure(mfilename)
    
%     c = kmeans(V,2);
%     
%     figure
%     subplot(2,1,1)
%     plot_confidence_intervals(RF.PSD_Fqs,V(c==1,:));
%     plot_confidence_intervals(RF.PSD_Fqs,V(c==2,:),[],'r');
%     subplot(2,1,2)
%     [pc,sc] = princomp(V);
%     plot(sc(:,1),sc(:,2),'.')
%     
    
    figure
    subplot(1,2,1)
    plot(RF.EstRipFreq)
    hold on
    plot(RF.PeakRipFreq,'r')
    legend('Est','PeakDb')
    subplot(1,2,2)
    plot(RF.PeakRipFreq,RF.EstRipFreq, 'k.')
    lsline
    
    figure
    plot(RF.SpectPeakRipFreq,RF.EstRipFreq, 'k.')
    
    figure
    plot(RF.SpectPeakRipFreq,RF.PeakRipFreq, 'k.')
    
    
    [h,p1]=ttest(RF.WithinRipMeanIntervalChangeMsec);
    mean(RF.WithinRipMeanIntervalChangeMsec)
    [h,p2]=ttest(RF.WithinRipChangeRegressSlope);
    mean(RF.WithinRipChangeRegressSlope)
    
    figure
    subplot(2,3,1)
    hist(RF.WithinRipMeanIntervalChangeMsec,50);
    title('WithinRipMeanIntervalChangeMsec')
    subplot(2,3,2)
    hist(RF.WithinRipChangeRegressSlope,50);
    title('WithinRipChangeRegressSlope')
    subplot(2,3,3)
    hist(RF.EstRipFreq,50);
    title('EstRipFreq')
    subplot(2,3,4)
    hist(RF.PeakPowerAssymetry,50);
    title('PeakPowerAssymetry')
    subplot(2,3,5)
    hist(RF.MeanFiltEnergy,50);
    title('MeanFiltEnergy')
    subplot(2,3,6)
    hist(RF.PeakRipDeflection,50);
    title('PeakRipDeflection')
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Create a feature matrix for PCA and clustering and stuff.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     tmpRF = RF;
    %     tmpRF.riptimes_usec = RF.riptimes_usec(:,1);
    %     M = struct2array(tmpRF);
    %     col_names = fieldnames(tmpRF);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Try clusterdata or cluster for clustering the data to see what comes out.
    % also princomp will do principal components.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     figure
    %     plot( tmpRF.PeakToPeak_Duration_ms, tmpRF.MeanEnergy,'.')
    %     lsline
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % plot matrix
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     figure
    %     h = plotmatrix_cowen(M,M);
    %     for ii = 1:Rows(h)
    %         g = get(h(1,ii),'Parent');
    %         subplot(g)
    %         title(col_names{ii})
    %         g = get(h(ii,1),'Parent');
    %         subplot(g)
    %         ylabel(col_names{ii})
    %     end
end