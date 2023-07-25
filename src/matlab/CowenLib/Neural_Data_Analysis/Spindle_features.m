function [SF,SPNS] = Spindle_features(raw_filt_LFP, sptimes_sec)
%function [RF,RIPS] = Spindle_features(raw_filt_LFP, sptimes_sec)
% Generate some useful information about each spindle.
%
% INPUT:
%   raw_filt_LFP:
%    First col - timestamps in usec
%    Second col - raw spindle data.
%    Third col - filtered spindle data.
%
%  sptimes_sec_usec = the start and end times (usec) of each spindle
%
%  OUTPUT:
%  RF - spindle features - useful data about each spindle.
%  RIPS - the raw spindle waveforms.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
before_after_sp_sec = .5; % time before and after the spindle (buffer - for filtering).

% the use of structures is a great way to organize your data.
plot_it = true;
nSpindles = Rows(sptimes_sec);
SF.sptimes_sec = sptimes_sec;
SF.sp_times_p2p_usec = sptimes_sec*nan;

SF.PeakToPeak_Duration_ms = zeros(nSpindles,1)*nan;
SF.Std = zeros(nSpindles,1)*nan;
SF.Max = zeros(nSpindles,1)*nan;
SF.Min = zeros(nSpindles,1)*nan;
SF.InterPeakStd_msec = zeros(nSpindles,1)*nan;
SF.InterPeakMean_msec = zeros(nSpindles,1)*nan;
SF.InterPeakFano = zeros(nSpindles,1)*nan;
SF.MeanFiltEnergy = zeros(nSpindles,1)*nan;
SF.Mean = zeros(nSpindles,1)*nan;
SF.nPeaks = zeros(nSpindles,1)*nan;
SF.WithinRipMeanIntervalChangeMsec = zeros(nSpindles,1)*nan;
SF.WithinRipChangeRegressSlope = zeros(nSpindles,1)*nan;
SF.PeakRipDeflection= zeros(nSpindles,1)*nan;
SF.SampEntropy = zeros(nSpindles,1)*nan;

SF.EstRipFreq = zeros(nSpindles,1)*nan;
SF.PeakSpnFreq = zeros(nSpindles,1)*nan;

SF.SpectPeakSpnFreq = zeros(nSpindles,1)*nan;
SF.SpectPeakPow = zeros(nSpindles,1)*nan;
SF.SpectPeakTimeAssymetry = zeros(nSpindles,1)*nan;
SF.SpectPeakSpnFreqStart= zeros(nSpindles,1)*nan;
SF.SpectPeakSpnFreqEnd= zeros(nSpindles,1)*nan;
SF.SpectPeakSpnFreqStartEndChange= zeros(nSpindles,1)*nan;
SF.SpectPeakRipPowStart= zeros(nSpindles,1)*nan;
SF.SpectPeakRipPowEnd= zeros(nSpindles,1)*nan;
SF.SpectPeakRipPowStartEndChange= zeros(nSpindles,1)*nan;

SF.TimeFromRestOnset_sec = zeros(nSpindles,1)*nan;
SF.PeakPowerTimes_usec = zeros(nSpindles,1)*nan;
SF.PeakPowerAssymetry = zeros(nSpindles,1)*nan;
SF.RipToGamPow= zeros(nSpindles,1)*nan;
SF.RipToHighPow= zeros(nSpindles,1)*nan;
SF.RipQualityRipToHGammaRatio = zeros(nSpindles,1)*nan;
SF.ProportionOfSaturatingPoints = zeros(nSpindles,1)*nan;
SF.MaxPowerDb = zeros(nSpindles,1)*nan;
SF.MaxHighGammaPowerDb = zeros(nSpindles,1)*nan;
SF.RipplePowerDb10  = zeros(nSpindles,1)*nan;
SF.RipplePowerDb20  = zeros(nSpindles,1)*nan;
SF.RipplePowerDb40  = zeros(nSpindles,1)*nan;
SF.RipplePowerDb400  = zeros(nSpindles,1)*nan;
SF.PSD_Fqs = 3:.2:70;
SF.SPN_IX = SF.PSD_Fqs>=9 & SF.PSD_Fqs<=16;
SF.HIGH_IX = SF.PSD_Fqs>=20 ;
SF.PSD_Fqs_Db = zeros(nSpindles,length(SF.PSD_Fqs ))*nan;

SPNS.FirstPeakInRip_sec = zeros(nSpindles,1)*nan;
SPNS.LastPeakInRip_sec  = zeros(nSpindles,1)*nan;
SPNS.raw_rips = cell(nSpindles,1);
SPNS.filt_rips = cell(nSpindles,1);
SPNS.x_msec = cell(nSpindles,1);

SF.pwelch_spindle = zeros(nSpindles,length(SF.PSD_Fqs));

sFreq= 1/median(diff(raw_filt_LFP(:,1)));

% profile on
tmpWAVE = zeros(nSpindles,length(SF.PSD_Fqs));
for iSpn = 1:nSpindles
    % Find the spindle that falls bewteen the identified range.
    
    st_sec = sptimes_sec(iSpn,1);
    ed_sec = sptimes_sec(iSpn,2);
    
    IX = raw_filt_LFP(:,1) >= st_sec & raw_filt_LFP(:,1) < ed_sec;
    IX_extended = raw_filt_LFP(:,1) >= st_sec - before_after_sp_sec & raw_filt_LFP(:,1) < ed_sec + before_after_sp_sec;
    start_ix = find(IX,1,'first');
    x_sec   = raw_filt_LFP(IX,1) - raw_filt_LFP(start_ix,1);
    raw_rip  = raw_filt_LFP(IX,2);
    if length(raw_rip) > 20
        SF.pwelch_spindle(iSpn,:) = pwelch(raw_rip,length(raw_rip),0,SF.PSD_Fqs, sFreq);
    else
        error('WTF')
    end
    
    raw_spn_extended = raw_filt_LFP(IX_extended,2);
    x_sec_extended  = raw_filt_LFP(IX_extended,1) - st_sec; % Time zero is the start of the spindle.
    
    SPNS.x_msec{iSpn} = single(x_sec_extended*1e3);
    SPNS.raw_rips{iSpn} = raw_spn_extended;
    SPNS.filt_rips{iSpn} = raw_filt_LFP(IX,3);
    [~,maxix] = max(abs(SPNS.filt_rips{iSpn}));
    
    whereitis = maxix/length(SPNS.filt_rips{iSpn});
    peak_power_spn_times = st_sec + (ed_sec - st_sec).*whereitis;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Where the peak spindle power is...
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % UPSAMPLE: to get precise measures of the peak times.
    upsamp_x_sec = linspace(x_sec(1),x_sec(end),length(x_sec)*10); % UPSAMPLE
    upsampLFPrip = interp1(x_sec, SPNS.filt_rips{iSpn},upsamp_x_sec,'spline');
    % find those peaks
    [pkfilt_ix] = Find_peaks_troughs_zeros(upsampLFPrip);
    % Inter-Peak variance...
    dfmsec = diff(upsamp_x_sec(pkfilt_ix))/1000;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % IPkI MEAN STD AND FANO
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Generate some features that may unravel the true nature of the
    % elusive spindle.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    SPNS.FirstPeakInRip_sec(iSpn) = st_sec + upsamp_x_sec(pkfilt_ix(1));
    SPNS.LastPeakInRip_sec(iSpn)  = st_sec + upsamp_x_sec(pkfilt_ix(end));
    
      
    SF.spn_times_p2p_usec(iSpn,1) = SPNS.FirstPeakInRip_sec(iSpn);
    SF.spn_times_p2p_usec(iSpn,2) = SPNS.LastPeakInRip_sec(iSpn);
    SF.InterPeakStd_msec(iSpn) = std(dfmsec);
    SF.InterPeakMean_msec(iSpn) = mean(dfmsec);
    SF.InterPeakFano(iSpn) = SF.InterPeakStd_msec(iSpn)/SF.InterPeakMean_msec(iSpn);
    SF.ProportionOfSaturatingPoints(iSpn) = sum(abs(raw_rip)>2030 | abs( [nan ;diff(raw_rip)]) < 0.01) /length(raw_rip); % A quality measure.
    
    % This is slow but it matches the results of my peak-counting method
    % much better than pmtm.
    
    %    [~, ~, freq, SCImg] = Wavelet_spindle(raw_rip, sFreq, [70 250],0.2);
    [SCImg, freq] = Spectrogram_spindle(raw_rip, sFreq, SF.PSD_Fqs);
    if ~isempty(SCImg)
        %     tic
        %     [~, ~, freq2, SCImg2] = Wavelet_spindle(raw_rip, sFreq, [20 450],0.2);
        %     toc
        % Time of peak
        [mx,tim_ix] = max(max(SCImg,[],1));
        mx_fq = SCImg(:,tim_ix);
        [~,fq_ix] = max(mx_fq);
        mn_fq = mean(SCImg,2);
        SF.PSD_Fqs_Db(iSpn,:)  = mx_fq;
        %     figure(22);clf;plot(SF.PSD_Fqs,mn_fq)
        %     mn_fq2 = pmtm(raw_rip,[],SF.PSD_Fqs,sFreq);
        %     figure(2);clf;plot(SF.PSD_Fqs,mn_fq2)
        
        % The spectrogram of the peak frequency.
        tmpWAVE(iSpn,:) = mn_fq';
        % Find peak time.
        [~,cl] = size(SCImg);
        SF.SpectPeakTimeAssymetry(iSpn) = (tim_ix/cl)-0.5;
        SF.SpectPeakSpnFreq(iSpn) = freq(fq_ix);
        SF.SpectPeakPow(iSpn) = mx;
        
        % Peak start and end frequency and power.
        [mx,ix] = max(SCImg);
        SF.SpectPeakSpnFreqStart(iSpn) = freq(ix(1)); %Peak power at start of spindle
        SF.SpectPeakSpnFreqEnd(iSpn)   = freq(ix(end)); %Peak power at end of spindle
        SF.SpectPeakSpnFreqStartEndChange(iSpn) = SF.SpectPeakSpnFreqEnd(iSpn)-SF.SpectPeakSpnFreqStart(iSpn); %Peak power at start of spindle
        %
        SF.SpectPeakRipPowStart(iSpn) = mx(1); %Peak power at start of spindle
        SF.SpectPeakRipPowEnd(iSpn)   = mx(end); %Peak power at start of spindle
        SF.SpectPeakRipPowStartEndChange(iSpn) =  mx(end)-mx(1); %Peak power at start of spindle
        
        fq_spn = freq(SF.SPN_IX);
        psd_spn = mx_fq(SF.SPN_IX);
        [mxspn,ix] = max(psd_spn);
        
        SF.PeakSpnFreq(iSpn) = fq_spn(ix);
        SF.MaxPowerDb(iSpn) = mxspn;
        
        fq_high = freq(SF.HIGH_IX);
        psd_high = mx_fq(SF.HIGH_IX);
        
        SF.RipToHighPow(iSpn) = mxspn - max(psd_high);

    end
    spn_dur_sec = upsamp_x_sec(pkfilt_ix(end)) - upsamp_x_sec(pkfilt_ix(1));
    
    SF.PeakPowerAssymetry(iSpn) = whereitis-0.5; % location of peak power relative to the start of the spindle. 0 = right in the middle
    SF.PeakToPeak_Duration_ms(iSpn) = spn_dur_sec*1e3;
    
    SF.EstRipFreq(iSpn) = length(pkfilt_ix)/(spn_dur_sec);
    
    SF.Std(iSpn) = std(raw_rip); % Don't know what this means.
    SF.Max(iSpn) = max(raw_rip);
    SF.Min(iSpn) = min(raw_rip);
    SF.Mean(iSpn) = mean(raw_rip);
    
    SF.PeakRipDeflection(iSpn) =  max(abs(raw_rip));
    SF.nPeaks(iSpn) =  length(pkfilt_ix);
    % is the spindle increasing or decreasing in fq?
    % need 2 diffs because you what to know how fast the INTERVALS between
    % spindles are changing.
    SF.WithinRipMeanIntervalChangeMsec(iSpn) = mean(diff(diff(upsamp_x_sec(pkfilt_ix))/1e3)); % POSITIVE is a DECREASE in frequency (increase in inter-spindle duration)
    warning off
    b = regress(diff(upsamp_x_sec(pkfilt_ix))',[ones(length(pkfilt_ix)-1,1) (1:(length(pkfilt_ix)-1))']);
    warning on
    SF.WithinRipChangeRegressSlope(iSpn) = b(2);
    % I comment SampleENtropy out sometimes as it is VERY slow relative to
    %     SF.SampEntropy(iSpn) = SampEn(2,0.2*std(raw_rip),raw_rip);
    SF.MeanFiltEnergy(iSpn) = mean(SPNS.filt_rips{iSpn}.^2);
    %
    SF.TimeFromRestOnset_sec(iSpn) = (sptimes_sec(iSpn,1)- sptimes_sec(1))/1e6;
    SF.PeakPowerTimes_usec(iSpn) = peak_power_spn_times;
    
    
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
        subplot(2,1,1)
        plot(x_sec_extended, raw_spn_extended)
        pubify_figure_axis
        xlabel('s')
        axis tight
        plot_vert_line_at_zero
        plot_vert_line_at_zero(upsamp_x_sec(end))
        subplot(2,1,2)
        
 
        plot(x_sec,raw_filt_LFP(IX,2))
        hold on
        plot(x_sec,raw_filt_LFP(IX,3),'r')
        plot(upsamp_x_sec(:),upsampLFPrip,'r')
        plot(upsamp_x_sec(pkfilt_ix),upsampLFPrip(pkfilt_ix),'g*')
        axis tight
        pubify_figure_axis
        xlabel('s')
        pause
        clf
    end
end
% profile viewer

if plot_it
    %%
 
    V  =  SF.PSD_Fqs_Db;
    V = tmpWAVE;
    figure
    subplot(3,1,1)
    imagesc(SF.PSD_Fqs, [], V);
    subplot(3,1,2)
    imagesc(SF.PSD_Fqs, [], sort_matrix( V));
    subplot(3,1,3)
    plot_confidence_intervals(SF.PSD_Fqs,V)
    label_figure(mfilename)
    
   
end