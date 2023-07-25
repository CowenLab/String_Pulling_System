function [OUT,OUTsh] = SPEC_spike_field_coherence_track_pk_fq(TS, DATA, sFreq, fq_range, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT: TS   cell array of action potential times.
%        DATA  col 1= timestamps in same units as TS, col 2 = unfiltered LFP
%        fq_range = the range (min and max) frequency to track.
%        other parameters can be accessed through varargin.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This approach computes the wavelet for the LFP. The peak frequency (in power) is used to determine which specific frequecy within fq_range will be used to estimate the phase.
% Once this peak frequency is determined, we use the imaginary component at this point to determine the phase at this point.
% Coupling to this moving frequency is determined by 1) rayleigh z and then
% 2) compoaring this to a shuffle distribution.
%
% TODO: Should despike the LFP before the STA computation to eliminate
% spurious effects caused by bursts where one spike is regulalry followed
% by another. Currently, the second spike would still have it's artifact in
% the LFP. I have the code in comments right now but will need validation.
%
% TODO: Look at whether phase-locking differs by optimal frequency by
% looking for unique preferred phases at different optimal frequencies.
%
% NOTE: reading Dvorak D, Fenton AA. 2014. Toward a proper estimation of phase-amplitude coupling in neural oscillations. J Neurosci Methods [Internet] 225:42–56. Available from: http://www.ncbi.nlm.nih.gov/pubmed/24447842
% This paper suggests the 95th percentile for estimating significant phase
% lock events within each frequency band. It also recommends z scoreing the raw LFP and the wavelet
% (which I do).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PLOT_IT = false;
DO_WHAT_REVIEWER_WANTS = false; % this was to remove the > mean power restriction. 
min_spikes = 30; % you should have at least this many spikes to even consider statistical significance.
STA_window_pts = round(sFreq/2); % value used by Halje... these are the points before or after so the full window is 2 times this.
max_spikes = 2000; % if you have more than this, it's overkill for the stats so you might as well just subsample this value or less. This can save time/RAM if you have a lot of spikes.
nboot = 400;
sig_power_percentile = 60; % Dvorak uses 99th percentile so much higher than this.
% thresh_norm_pow = 0; % ne
z_score_data = false;
REMOVE_SPIKE_FROM_LFP = false; % recommend this is kept to false as this can distort the data.
SUBTRACT_MEAN_PSD = false; % i think this is a bad idea overall.

method = 'wavelet'; % faster, but poorer frequency resolution and power
% at higher frequencies decreases, even if the sigal is equally powered
% (because the power is being spread out to neighboring frequencies). The
% phase also spreads ou,t
% method = 'hilbert'; % 'hilbert'  - slower - about 4x slower. Better freq.
% resolution. OVerall, results should be similar between the twol

Extract_varargin;
% detrend the data (perhaps Ideally this should be a moving mean).
DATA(:,2) = DATA(:,2)-nanmean(DATA(:,2));
if z_score_data % The Dvorak Fenton method does this. I worry about the division by std. It introduces an unknown into the data that depends on the amount of noise or artifact.
    DATA(:,2) = DATA(:,2)/nanstd(DATA(:,2));
end


if 0 % for testing. Check your assumptions. Let's try chirp.
    sFreq = 1000;
    time_dur_s = 20;
    tLFP = 0:1/sFreq:time_dur_s;
    y = chirp(tLFP,30,time_dur_s,120,'linear');
    %     y = chirp(tLFP,50,5,51,'linear'); % try something simple.
    [M,fqs] = SPEC_cwt_cowen(y,sFreq, 1:200);
    figure
    subplot(2,1,1)
    pspectrum(y,sFreq,'spectrogram','TimeResolution',0.1,'OverlapPercent',99,'Leakage',0.85);
    subplot(2,1,2)
    imagesc([],fqs,abs(M));axis xy;colorbar
    [~,ix] = findpeaks(y);
    tuS = tLFP(:)*1e6;
    pk_tuS = tuS(ix);
    % Create a perfectly phase aligned neuron, a jittered, and random.
    %     TS = {pk_tuS pk_tuS(:) + randn(size(pk_tuS))*10e3 unique(randsample(tuS,length(pk_tuS),false))};
    TS = {pk_tuS pk_tuS(:) + randn(size(pk_tuS))*10e3};
    DATA = [tuS(:)  y(:)];
    fq_range = [30 120];
    
    figure
    plot(DATA(:,1),DATA(:,2))
    hold on
    plot(TS{1},ones(size(TS{1})),'ro')
    plot(TS{2},ones(size(TS{1}))*.8,'g+')
    
    [OUT] = SPEC_spike_field_coherence_track_pk_fq(TS, DATA, sFreq, fq_range);
end
% For comparison, also analyze using the wideband filtered data.
f = designfilt('bandpassiir','FilterOrder',12, ...
    'HalfPowerFrequency1',fq_range(1),'HalfPowerFrequency2',fq_range(2), ...
    'SampleRate',sFreq);
% DATA(:,3) = filtfilt(f,DATA(:,2));
% DATA(:,4) = abs(hilbert(DATA(:,3))); % power
DATA(:,3) = angle(hilbert(filtfilt(f,DATA(:,2)))); % phase

psd_fqs = fq_range(1):.5:fq_range(end);

OUTsh = [];

if ~iscell(TS)
    TS = {TS};
end

for iN = 1:length(TS)
    OUT(iN).preferred_freq = nan; % The peak of the ksdensity est.
    OUT(iN).preferred_freq_median = nan;
    OUT(iN).preferred_phase = nan;
    OUT(iN).mean_power = nan;
    OUT(iN).mean_power_above_base = nan;
    OUT(iN).circ_p_to_shuff = nan; % this is the main sig test you should use.
    OUT(iN).circ_z_to_shuff = nan;
    OUT(iN).circ_rtest_p = nan; % This is the raw result of circ Raylaegh test.
    OUT(iN).circ_rtest_z = nan;
    OUT(iN).circ_rtest_sh_p = nan; 
    OUT(iN).circ_rtest_sh_z = nan;
    OUT(iN).freq_pow_r = nan;
    OUT(iN).freq_pow_p = nan;
    OUT(iN).freq_phase_r = nan;
    OUT(iN).freq_phase_p = nan;
    OUT(iN).psd_fqs = psd_fqs; % psd frequencies used
    OUT(iN).circ_rtest_wideband_p = nan; % This is using the traditional measure of phase locking (but without shuffle control).
    OUT(iN).circ_rtest_wideband_z = nan;
    OUT(iN).wideband_mean_phase = nan; % Phase chosen using the wideband filter. Compare with tracked phase to see if they are the same or different.
    % Compare coupling at low and high frequencies.
    OUT(iN).circ_rtest_upfreq_p = nan;
    OUT(iN).circ_rtest_upfreq_z = nan;
    OUT(iN).circ_rtest_downfreq_p = nan;
    OUT(iN).circ_rtest_downfreq_z = nan;
    OUT(iN).preferred_phase_up = nan;
    OUT(iN).preferred_phase_down = nan;
    OUT(iN).circ_ktest_updownfreq_p = nan;
    OUT(iN).circ_ktest_updownfreq_k = nan;
    
    %
    OUT(iN).pk_freq = [];
    OUT(iN).pk_pow = [];
    OUT(iN).pk_phase = [];
    %     OUT(iN).POW_STA = [];
    %     OUT(iN).ANG_STA = [];
end

% NOTE: To deal with the 1/f problem, I could randomly sample the PSD in
% from DATA and use this to estimate the rolloff (could fit to an
% exponetial) and then subtract this from the wavelet. Even an LS line
% would do.
% Determine a baseline for comparison
ix = round(linspace(1,Rows(DATA),200));
[ST]=PETH_EEG_simple(DATA(:,1:2), DATA(ix,1),STA_window_pts,STA_window_pts,sFreq);
% remove artifact.
th_LFP = prctile(max(abs(ST),[],2) ,99);
GIX = ~isnan(sum(ST,2)) & (max(abs(ST),[],2) < th_LFP);
ST = ST(GIX,:);
ST = ST - mean(ST,2,'omitnan');
ST = ST';
ST = ST(:);
switch method
    
    case 'hilbert'
        [mn_psd,~,psd_up_lim] = pwelch(ST,length(ST),0,psd_fqs,sFreq,'ConfidenceLevel',p_th );
        psd_up_lim = psd_up_lim(:,2)';
    case 'wavelet'
        cwt_data = SPEC_cwt_cowen(ST,sFreq, psd_fqs);
        %         pw = abs(cwt_data).^2./std(cwt_data,[],2).^2; % From Dvorak and Fenton
        mn_psd = mean(abs(cwt_data),2,'omitnan')'; % This works, but median does not at some frequencies - where power is lower. Not sure why.
        [tmp] = prctile(abs(cwt_data(:,1:10:end)'),[50 sig_power_percentile]);  %Dvorak used 2.5 std wich is closer to the upper 99th percentile but in another paper they use the 95th percentile.
        %         mn_psd = tmp(1,:);
        if 0
            imagesc([],psd_fqs,abs(cwt_data)); axis xy
            %             imagesc([],psd_fqs,pw); axis xy
        end
        psd_up_lim = tmp(2,:);
        
end
if DO_WHAT_REVIEWER_WANTS
    thresh_mn_psd = min(mn_psd); % NOTE: In the rebuttal for JNeuro, the reviewers want to know what happens if you do not use a threshold. Thus I will NOW add a condition here.
else
    thresh_mn_psd = mean(mn_psd); % THIS IS WHAT NEEDS TO BE DONE FOR THE REAL ANALYSIS
end
% mn_psd_n = mn_psd - nanmean(mn_psd);
% sd_psd = std(abs(cwt_data),0,2,'omitnan');
% sig_psd_up = mn_psd + 1.96*sd_psd; % TODO: we can use this to limit analyses to power fluctuations that are actually big enough mean something.
% sig_psd_down = mn_psd - 1.96*sd_psd;
% plot(psd_fqs, mn_psd,psd_fqs, sig_psd_up); % plot_confidence_intervals(abs(cwt_data)')

% Determine the peak frequency for each timepoint in the data.
% inst_freq = instfreq(DATA,sFreq,'FrequencyLimits',fq_range); % NOTE - this is not exaclty what you want - but useful for estimating hte range of frequencies.
% if PLOT_IT
%     figure
%     plot(inst_freq)
% end

% Rid ourselves of spikes on the edge of the LFP so that the STA does not
% get confused by non-existent LFP for spikes on the edge.
TS = Restrict(TS,DATA(STA_window_pts+2,1),DATA(end-STA_window_pts-2,1));
STAGIX = true(1,STA_window_pts*2+1);
% Get rid of LFP data (and interpolate) around action potentials to reduce
% chace of artifact.
if REMOVE_SPIKE_FROM_LFP
    % NOTE: this can distort the data and mess up the phase estimate.
    % I noticed this for LFP at 1000 hz and for frequencies > 50Hz.
    % Perhaps at higher sampling rates this would be improved.
    % UPSHOT: I recommend avoiding this unless really necessary.
    npts_spike = ceil(.003*sFreq);
    cix = (STA_window_pts + 1 - npts_spike):(STA_window_pts + 1 + npts_spike);
    STAGIX(cix) = false;
    
end

for iN = 1:length(TS)
    fprintf('N%02.0f',iN);
    
    T = TS{iN};
    if length(T) < min_spikes
        continue
    end
    OUT(iN).orig_ix = 1:length(T);
    if length(T) > max_spikes
        % orig_ix stores the original index in T so that phase/power per
        % spike can be linked back to behavioral or other variables.
        %         disp([num2str(iN) ') ' num2str(length(T)) ' spikes, subsampling to ' num2str(max_spikes) ' spikes, see orig_ix.'])
        tmp = unique(randsample(T,max_spikes,0));
        [~, OUT(iN).orig_ix] = intersect(T,tmp);
        T = tmp;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Compute the sta of the LFP
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % THE PROBELM IS HERE_ EACH SPIKE SHOULD BE ON THE PEAK! NOT THE CASE>
    [STA_LFP,~,OUT(iN).STA_x_sec]=PETH_EEG_simple(DATA(:,1:2), T,STA_window_pts,STA_window_pts,sFreq);
    GOODROWSIX = ~isnan(sum(STA_LFP,2)) & (max(abs(STA_LFP),[],2) < th_LFP) ;
    if sum(GOODROWSIX) < min_spikes
        continue
    end
    
    STA_LFP = STA_LFP(GOODROWSIX,:);
    %     figure; plot(DATA(:,1),DATA(:,2));hold on; plot(T,ones(size(T)),'r*');
    % find the peak frequency for each action potential.
    zero_ix = find(OUT(iN).STA_x_sec >= 0,1,'first');
    n_rand_samp = round(4000/Rows(STA_LFP));
    
    OUT(iN).fq_range = fq_range;
    OUT(iN).psd_fqs = single(psd_fqs);
    %     allPOW = nan(length(psd_fqs),STA_window_pts*2+1,Rows(STA_LFP));
    %     allANG = nan(length(psd_fqs),STA_window_pts*2+1,Rows(STA_LFP));
    pk_freq = nan(Rows(STA_LFP),1);
    pk_pow = nan(Rows(STA_LFP),1);
    pk_pow_raw = nan(Rows(STA_LFP),1);
    pk_phase = nan(Rows(STA_LFP),1);
    pk_phase_sh = []; % Shuffle null distribution.
    for iM = 1:Rows(STA_LFP)
        notNAN = ~isnan(STA_LFP(iM,:));
        % the following should be eliminated once I pull spikes out of the
        % LFP prior (see TODO).
        STA_LFP(iM,~STAGIX) = interp1(OUT(iN).STA_x_sec(STAGIX & notNAN),STA_LFP(iM,STAGIX & notNAN),OUT(iN).STA_x_sec(~STAGIX),'spline');
        %         STA_LFP(iM,:) = STA_LFP(iM,:)-nanmean(STA_LFP(iM,1:round(STA_window_pts/2))); % get rid of slow variation
        STA_LFP(iM,:) = STA_LFP(iM,:)-nanmean(STA_LFP(iM,:)); % get rid of slow variation
        %         % wavelet does not give a clean frequency response.
        v_ang = [];
        switch method
            case 'hilbert'
                v_pow = pwelch(STA_LFP(iM,:),length(STA_LFP(iM,:)),0,psd_fqs,sFreq );
                %                 v_pow = pburg(STA_LFP(iM,:),41,psd_fqs,sFreq ); % An alternative to consider. Need to do this for the baseline too.
            case 'wavelet'
                cwt_data = SPEC_cwt_cowen(STA_LFP(iM,:),sFreq, psd_fqs);
                
                POW = abs(cwt_data); % cwt power at every time and frequency
                ANG = angle(cwt_data); % phase angle at every time and frequency
                v_pow = POW(:,zero_ix)';
                v_ang = ANG(:,zero_ix)';
                %         allPOW(:,:,iM) = POW;
                %         allANG(:,:,iM) = ANG;
                % % I think that I should shuffle here - not globally - due
                % to non-stationarities
                if 0
                    % pretty plots to make the point that finding phase at
                    % peak power is important.
                    XIX = OUT(iN).STA_x_sec > -.06 & OUT(iN).STA_x_sec < .06;
                    figure(1)
                    clf
                    subplot(1,7,1:3)
                    imagesc(OUT(iN).STA_x_sec(XIX),psd_fqs,POW(:,XIX))
                    colorbar
                    axis xy
                    plot_vert_line_at_zero
                    xlabel('sec')
                    ylabel('Hz')
                    title('power')
                    pubify_figure_axis
                    subplot(1,7,4:6)
                    imagesc(OUT(iN).STA_x_sec(XIX),psd_fqs,ANG(:,XIX))
                    colorbar
                    axis xy
                    plot_vert_line_at_zero
                    xlabel('sec')
                    title('phase')
                    pubify_figure_axis
                    
                    subplot(1,7,7)
                    %                     quiver(ones(Rows(ANG),1),psd_fqs,sin(v_ang),cos(v_ang),.02)
                    %                     plot(rad2deg(v_ang(:)), psd_fqs(:),'.-')
                    %                     axis tight
                    %                     hold on
                    plot(rad2deg(circ_dist(v_ang(:),circ_mean(v_ang(:)))), psd_fqs(:),'-');
                    axis tight
                    %                     plot(abs(rad2deg(circ_dist(v_ang(:),circ_mean(v_ang(:))))), psd_fqs(:),'.-');
                    set(gca,'XLim',[-182 182])
                    %                     xlabel('ph & dev. frm mn ph (deg)')
                    xlabel('dev. frm mn ph (deg)')
                    title('phase at t=0')
                    plot_vert_line_at_zero
                    pubify_figure_axis
                    
                    set(gcf,'Position',[1636.2        420.2       1353.6        380.8])
                    pause
                end
            otherwise
                error('error ');
        end
        if SUBTRACT_MEAN_PSD
            v = (v_pow - mn_psd);%; % reduce the 1/f contribution and convert to z Is this legit?
            % The problem here is that you are no longer basing things on the
            % actual local power of the 'oscillation' but on the power relative
            % to the mean. This indeed can shift whwer the peak power is
            % determined (as I can see in some examples) - and especially at low freqeuncies where 1/f does not really apply so well. Indeed, I look for
            % peaks - not abs power. The 1/f should take care of most of this.
            % instead of subtracting the mean - probably should subtract some
            % exponential. The case where this is really messed up is theta
            % where the mean has a HUGE peak at theta. Subtracting this -
            % distorts things clearly.
            % For higher frequencies, it might make sense to fit an
            % exponential or a low-order polynomial to the mean PSD of the
            % entire period and then subtract this.
        else
            v = v_pow;
        end
        v(v<0) = 0; % in the future - we need a larger threshold here or just pass in good data - not low gamma data.
        first_ix = find(~isnan(v),1,'first');
        last_ix = find(~isnan(v),1,'last');
        
        [pk,pk_fq_ix] = findpeaks(v);
        % Find peaks that are below the mean power - they can't really be
        % significant power peaks...
        GIX = (pk - mn_psd(pk_fq_ix)) > 0;
        pk = pk(GIX); 
        pk_fq_ix = pk_fq_ix(GIX);
        
        if ~isempty(pk_fq_ix)
            % If the peak is at the very left or right edge, eliminate as
            % it is not a 'peak' per se - just an edge effect.
            pk(pk_fq_ix <= first_ix) = [];
            pk_fq_ix(pk_fq_ix <= first_ix) = [];
            if ~isempty(pk_fq_ix)
                if pk_fq_ix(end) == last_ix
                    pk(end) = [];
                    pk_fq_ix(end) = [];
                end
            end
            
        end
        % if the chosen peak is at the far left, then choose the next max peak, if one
        % exists.
        if ~isempty(pk_fq_ix)
            % best guess is the max.
            if length(pk) > 1
                [~,ix]= max(pk); % choose the next BIGGEST peak.
                pk = pk(ix);
                pk_fq_ix = pk_fq_ix(ix);
            end
            pk_freq(iM) = psd_fqs(pk_fq_ix);
            pk_pow(iM) = pk;
            pk_pow_raw(iM) = v_pow(pk_fq_ix);
            switch method
                case 'hilbert'
                    % SLOWER, but old school and easier to undertand
                    % perhaps  - better frequency resolution.
                    % Determine the band frequencies. Define as 1/2 peak
                    th = pk/2;
                    start_ix = find(v(1:pk_fq_ix) < th,1,'last');
                    if isempty(start_ix)
                        start_ix = 1;
                    end
                    
                    end_ix = find(v(pk_fq_ix:end) < th,1,'first');
                    if isempty(end_ix)
                        end_ix = length(psd_fqs);
                    else
                        end_ix = end_ix + pk_fq_ix;
                    end
                    bands = [psd_fqs(start_ix) - 2 psd_fqs(end_ix) + 2];
                    abands(iM,:) = bands;
                    f2 = designfilt('bandpassiir','FilterOrder',12, 'HalfPowerFrequency1',bands(1),'HalfPowerFrequency2',bands(2), 'SampleRate',sFreq);
                    v2 = filtfilt(f2,STA_LFP(iM,:));
                    a2 = angle(hilbert(v2));
                    pk_phase(iM) = a2(zero_ix);
                    pk_phase_sh = [pk_phase_sh; randsample(a2(:),n_rand_samp)];
                    
                case 'wavelet'
                    pk_phase(iM) = v_ang(pk_fq_ix);
                    pk_phase_sh = [pk_phase_sh; randsample(ANG(:),n_rand_samp)];
                    
            end
        end
        
    end
    pk_phase_sh = pk_phase_sh(~isnan(pk_phase_sh));
    GGIX = ~isnan(pk_phase) & pk_pow > thresh_mn_psd; % Get rid of points where the power was less than some value above or at baseline. Seem reasonable and gets rid of 'peaks' that were below the baseline which should not happen.
    if sum(GGIX) > 10
        %         OUT(iN).POW_STA = single(mean(allPOW(:,:,GGIX),3,'omitnan'));
        %         OUT(iN).ANG_STA = single(mean(allANG(:,:,GGIX),3,'omitnan'));
        OUT(iN).mean_power = mean(pk_pow_raw(GGIX));
        OUT(iN).mean_power_above_base = mean(pk_pow(GGIX));
        [OUT(iN).circ_rtest_p, OUT(iN).circ_rtest_z] = circ_rtest(pk_phase(GGIX));
        [OUT(iN).circ_rtest_sh_p, OUT(iN).circ_rtest_sh_z] = circ_rtest(pk_phase_sh);
        
        ph = interp1(DATA(:,1),DATA(:,3),T(GGIX),'nearest');
        [OUT(iN).circ_rtest_wideband_p, OUT(iN).circ_rtest_wideband_z] = circ_rtest(ph);
        OUT(iN).wideband_mean_phase = circ_mean(ph);
        % Compare z values and phases for the low and high range of gamma.
        % Hypothesis: there may be better coupling at different frequency
        % bands. We would predict that old rats - their brains just can't
        % keep up with fast oscillations (but are OK with slower
        % oscillations) so this analysis should show stronger coupling at
        % the low end relative to the high end.
        % IF thre is an effect, this also argues that the general approach
        % of searching for hte optimal phase is valid.
        th = nanmedian(pk_freq(GGIX)); % simple median split.
        UPIX = GGIX & (pk_freq > th);
        DOWNIX = GGIX & (pk_freq < th);
        if sum(UPIX) > 15 && sum(DOWNIX) > 15
            
            [OUT(iN).circ_rtest_upfreq_p, OUT(iN).circ_rtest_upfreq_z] = circ_rtest(pk_phase(UPIX));
            [OUT(iN).circ_rtest_downfreq_p, OUT(iN).circ_rtest_downfreq_z] = circ_rtest(pk_phase(DOWNIX));
            OUT(iN).preferred_phase_up = circ_mean(pk_phase(UPIX));
            OUT(iN).preferred_phase_down = circ_mean(pk_phase(DOWNIX));
            warning off
            [OUT(iN).circ_ktest_updownfreq_p, OUT(iN).circ_ktest_updownfreq_k]  = circ_ktest(pk_phase(UPIX), pk_phase(DOWNIX));
            warning on
        end
        %
        cz = nan(nboot,1);
        %         tic
        %         czb = bootstrp(nboot,@circ_rtest_boot,pk_phase_sh); % I
        %         am confuesd as to why this gives different results than
        %         the for loop below.
        %         toc
        %         tic
        for ii = 1:nboot
            [~,cz(ii)] = circ_rtest(randsample(pk_phase_sh,500,true));
        end
        %         toc
        OUT(iN).circ_z_to_shuff = (OUT(iN).circ_rtest_z - mean(cz))/std(cz);
        OUT(iN).circ_p_to_shuff = 1-ksdensity(cz,OUT(iN).circ_rtest_z ,'Support','positive', 'Function','cdf');
        [fx,xi] = ksdensity(pk_freq(GGIX),psd_fqs); % I found that support does not help in this case.
        [~,ix] = max(fx);
        OUT(iN).preferred_freq = xi(ix);
        OUT(iN).preferred_freq_median = nanmedian(pk_freq(GGIX));
        OUT(iN).preferred_phase = circ_mean(pk_phase(GGIX));
        OUT(iN).pk_freq = single(pk_freq(GGIX));
        OUT(iN).pk_pow = single(pk_pow(GGIX));
        OUT(iN).pk_phase = single(pk_phase(GGIX));
        OUT(iN).ts_used = T(GGIX); % this will allow you to link these data back to behaviora/spatial/speed parameters from the original data for regression.
        OUT(iN).ts_omitted = T(~GGIX); % may be useful to assess the low-power events for contrast and control.
        
        [OUT(iN).freq_pow_r,OUT(iN).freq_pow_p] = corr(pk_freq(GGIX),pk_pow(GGIX),'Rows','pairwise');
        [OUT(iN).freq_phase_r,OUT(iN).freq_phase_p] = circ_corrcl(pk_phase(GGIX),pk_freq(GGIX));
        
    end
    
    fprintf('\b\b\b');
end


if nargout > 1
    TSsh = cell(size(TS));
    for iN = 1:length(TS)
        if length(TS{iN}) > min_spikes
            t_sh = [];
            for ii = 1:4
                t_sh = [t_sh;Shuffle_ISIs(TS{iN})];
            end
            t_sh = Restrict(unique(t_sh),DATA(STA_window_pts,1),DATA(end-STA_window_pts,1));
            m = min([length(t_sh) 1000]);
            TSsh{iN} = unique(randsample(t_sh,m,0));
        end
    end
    [OUTsh] = SPEC_spike_field_coherence_track_pk_fq(TSsh, DATA, sFreq, fq_range);
end


if PLOT_IT
    SPEC_spike_field_coherence_track_pk_fq_plot(OUT);
end

