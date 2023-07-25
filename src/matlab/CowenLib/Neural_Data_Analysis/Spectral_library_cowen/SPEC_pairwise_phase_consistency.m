function [PPC] = SPEC_pairwise_phase_consistency(TuS, TuS_PHASE, varargin)
% STATUS: ready to be run with real data - but be wary as this is a very
% recently developed function. 
%
% INPUT:
% T = time of each action potenital (vector or cell array)
%
% T_PHASE = 2 col matrix where this is from the continuous LFP data for teh
% phase of the LFP signal for the time period within the range of T.
%
% time_window = time between spikes that should be greater than what you
% might expect for artifactual pairwise phase measures (e.g., if there is a
% burst or refractoriness and you expect a burst + refractoryness to be < 200 ms, then the window should be >
% 200ms (could even be a second or two).
%
% This "point-field phase synchronization" method is presented as a sub-method in Vinck2012 and is based mostly
% on Vinck2010. The modifications presented in 2012 add a window-control to
% address the issue of non-independence (due to bursting/etc) by sampling
% spike pairs between windows instead of within windows.
%
% This is NOT the spike-train-to-phase synchronization method described in
% Vinck2012. That is a very different approach that computes the spectra of
% both the spike train and LFP - and I don't quite get it - seems like it
% would lead to false negatives.
%
% M. Vinck, M. van Wingerden, T. Womelsdorf, P. Fries, C. M. a Pennartz, The pairwise phase consistency: a bias-free measure of rhythmic neuronal synchronization. Neuroimage. 51, 112–122 (2010).
%
% There are two newish measures of phase-locking to LFP that differ from
% traditional measures. Traditional measures traditionally simply compare the distribution of LFP phases at the time of each spike to a null distribution (Van Mises or shuffle) to determine phase locking.
% Vinck 2010 showed that this is distorted and increased monotonically by
% the number of action potentials.
% This lead to the Vinck 2010 method of pairwise phase consistency which
% looks at distances (in angle) of all posible pairwise combos of phase and
% compars this to a null distribution. This addressess the firing rate
% issue, but Vinck 2012 mentions additional problems and presents yet
% another technique - but I have had a hard time implementing and understanding that technique and it seems to have less sensitivity than other approaches. The upshot of the Vinck2012 approach is that it uses PPC but only compares phases BETWEEN trials and not within trials - and this better addresses issues of non-stationarities as you are no longer say comparing 2 spikes in a single burst which obviously will be close in phase due to the physics of a bursting cell and not due to phase locking and thus over-state the ppc.
% The bigger issue that comes up here for our data is that WE TYPICALLY DO
% NOT HAVE TRIALS. As a result, we need to figure out a way to 'define'
% trials. This, in principle, seems straightforward - just choose a time
% window that is greater than the window expected for bursting and add a
% little more for good measure (say 5 seconds) and then only compare phases
% from spikes say between non-adjactent windows.
% Or, for each spike, only compare its phase to phases greater or less than certain
% time from when it happended (e.g., 1 sec). That should get rid of the
% impact of bursting and non-stationarities. This can also be compared to a
% 'shift' distribution (not shuffle as shuffle would kill the time-order of
% bursts of 3 spikes in a row and stuff0 where you shift the original spike
% train by say a random value of +/- 2 seconds (but kill shifts that are
% close to zero).

%
%The present code is based on the Vinck 2010 approach.
% IN PROGRESS: I should use this measure as it is quite common. Not sure
% what it gives you beyond Rayleigh though.
%
% Roughly based on Vinck2010. Incorporates local shuffle control.
% PPC values are z scores or p values relative to the shuffle control. This
% works by computing the circular distance (or dot product) between all
% possible spike-phase combinations in T (this could be a huge number of
% comparisons for a large number of spikes so subsampling is used if too
% big). The mean dot product or circ-dist measure is compared against the
% result from a local shuffle control. (note: the field trip implementation
% is rediculously opaque so I had to write this).
%
%
% OUTPUT
%
% Cowen 2021
nboot = 200;
time_window_uS = 20e6;
min_skip_time_uS = 2e6;
intervals_uS = []; % if 'trials' are used (e.g., presenting a stimulus, then this would be a trial x 2 matrix of start and end times)
shuffle_method = 'windowed_shuffleISI';
jitter_uS = 4e6;
bootstrap = true;
min_spikes = 20;

Extract_varargin;

if isempty(intervals_uS)
    intervals_uS = TuS_PHASE(1,1):time_window_uS:TuS_PHASE(end,1);
    intervals_uS(end) = TuS_PHASE(end,1);
end

PPC = [];
PPC.pval = nan;
PPC.mean_angle = nan;
PPC.z = nan;
PPC.Pdist = [];
PPC.interval_centers_uS = intervals_uS(1:end-1) + time_window_uS/2;
PPC.pval_interval = nan(length(intervals_uS)-1,1);
PPC.z_interval = nan(length(intervals_uS)-1,1);
PPC.z_interval_mean = nan;
PPC.mean_angle_interval = nan(length(intervals_uS)-1,1);

if 0
    % make some 'fake' surrogate data for testing.
    
    sFreq = 200;
    osc_freq = 11;
    duration_sec = 5*60;
    tgt_ph = pi/8;
    gain_modulation_fq_factor = [0.5  ; .1  ]; % should be divisible into the associated value in Frequencies.
    % The problem with this for testing is that the frequency is fixed -
    % needs to change slowly or sporatically like real LFP - otherwise the
    % shuffle and offset will never look right.
    [L, INFO] = Artificial_LFP(sFreq, duration_sec, osc_freq, gain_modulation_fq_factor, 0.1 );
    
    t_lfp_uS = INFO.T*1e6;
    ph = angle(hilbert(L));
         phs = randn(400,1)*.4 + tgt_ph;
%     phs = randn(400,1)*2.4 + tgt_ph;
    % Find a close match for each of these phases in the data and call this
    % a spike.
    cnt = 1;
    all_ix = [];
    spk = [];
    for ii = 1:length(phs)
        ix = find(ph > phs(ii) - .1 & ph < phs(ii) + .1);
        if ~isempty(ix)
            iix = randsample(ix,1);
            all_ix(cnt) = iix(1);
            spk(cnt) = t_lfp_uS(iix(1));
            cnt = cnt + 1;
        end
    end
    [TuS,ia] = unique(spk);
    all_ix = all_ix(ia);
    figure
    polarhistogram(ph(all_ix),30)
    
    TuS_PHASE = [t_lfp_uS(:) ph(:)];
    [PPC] = SPEC_pairwise_phase_consistency(TuS, TuS_PHASE);
    return
end

% Find the nearest phase for each action potential.
Ph = interp1(TuS_PHASE(:,1),TuS_PHASE(:,2),TuS, 'nearest');
Ph = Ph(:);
TuS = TuS(:);
% find the time between each possible spike pair
Tdist = pdist(TuS(:));
GIX = Tdist > min_skip_time_uS;
if sum(GIX) < min_spikes
    return
end
% Use pdist and circ_dist to compare all possible combinations in phase distance and time distance.
Pdist = pdist(Ph,@circ_dist);
PPC.Pdist = Pdist(GIX);
PPC.mean_angle = circ_mean(Ph);

%%%%%
% Compute the PPC for the entire period, all at once.
[PPC.pval, PPC.z] = circ_rtest(Pdist(GIX));
% Do this, but for the windows specified and then average these values.
% The interval approach is good if you expect the precise phase that spikes
% lock to slowly changes over time - or if there are generally
% non-stationarities in the data.
for ii = 1:length(intervals_uS)-1
    IX = TuS >= intervals_uS(ii) & TuS < intervals_uS(ii+1);
    if sum(IX) >= min_spikes
        Pdist = pdist(Ph(IX),@circ_dist);
        Tdist = pdist(TuS(IX));
        GIX = Tdist > min_skip_time_uS;
        if sum(GIX) >= min_spikes
            [PPC.pval_interval(ii), PPC.z_interval(ii)] = circ_rtest(Pdist);
            PPC.mean_angle_interval(ii) = circ_mean(Ph(IX));
        end
    end
end
PPC.z_interval_mean = nanmean(PPC.z_interval);

% Create nboot shuffled spike trains.
% Then run this function on all of those spike trains.
if bootstrap
    zboot = nan(nboot,1);
    Tsamp = cell(nboot,1);
    switch shuffle_method
        case 'jitter'
            for iB = 1:nboot
                Tsamp = TuS(:);
                jit = (rand(size(Tsamp)))*jitter_uS +.2e6;
                jit = jit - mean(jit);
                Tsamp = Tsamp + jit;
                % restrict to range of data
                Tsamp{iB} = Tsamp(Tsamp > TuS_PHASE(1,1) & Tsamp < TuS_PHASE(end,1));
            end
            
        case 'windowed_shuffleISI'
            % Better. Akin to Vinck 2012 and others..
            % Deals better with non-stationarities.
            ISIs = diff(TuS);
            shuff_ISIs = nan(size(ISIs));
            window_ID = nan(size(ISIs));
            for iB = 1:nboot
                % Jitter-shuffle procedure.
                % Adding pure randomness to the spikes (while probably good enough)
                % disrupts the inherent statistics of original ISIs - would disrupt
                % situations where there are regular bursts with say reliable 10ms ISIs
                % by adding random noise. To avoid this, I keep the original ISI
                % distribution (for pairs of spikes - not triplets) but shuffle the
                % intervals in windows (windows to addresss issue of non-stationarity - see many papers like Vinck2012)
                % Procedure: 1) First jitter the start time of the first AP relative to the global
                % start time. 2) Do a random reshuffling of ISIs for every cumulative
                % ISI window of 2s or greater.
                start_jit = (rand(1,1)-.5)*jitter_uS +.5e6;
                start_T = TuS(1) + start_jit;
                % Now play with the ISI distribution.
                cum_ISI = 0;
                last_ix = 1;
                window_count = 1; % use this with pdist to elim spike-phse pairs from same trial.
                for ii = 1:length(ISIs)
                    cum_ISI = cum_ISI + ISIs(ii);
                    if cum_ISI >= time_window_uS
                        % Shuffle
                        tmpISI = ISIs(last_ix+1:ii);
                        tmpISI = tmpISI(randperm(length(tmpISI)));
                        shuff_ISIs(last_ix+1:ii) = tmpISI;
                        window_ID(last_ix+1:ii) = window_count;
                        
                        window_count = window_count + 1;
                        cum_ISI = 0;
                        last_ix = ii;
                    end
                end
                % Reconstitute as spike train.
                T = start_T + cumsum(shuff_ISIs,'omitnan');
                % restrict to range of data
                Tsamp{iB} = T(T > TuS_PHASE(1,1) & T < TuS_PHASE(end,1));
                Tsamp{iB} = unique(Tsamp{iB});
            end
        otherwise
            error('wrong shuffle type')
    end
    % Created the surrogate ts, now compute phase coupling for each one
    % (ppc/Rayleigh z)
    for iB = 1:nboot
        if length(varargin) <= 1
            PPCboot = SPEC_pairwise_phase_consistency(Tsamp{iB}, TuS_PHASE, 'bootstrap', false);
        else
            PPCboot = SPEC_pairwise_phase_consistency(Tsamp{iB}, TuS_PHASE, 'bootstrap', false, varargin);
        end
        zboot(iB) = PPCboot.z;
        zboot_interval_mean(iB) = PPCboot.z_interval_mean;
        % Compare with the original
        warning off
        % Issue:stragely - the following is rarely < 0.05 when it should be
        % (using fake data). Probably doing something wrong here.
        pcomp(iB) = circ_ktest(PPC.Pdist, PPCboot.Pdist);
        %         pcompww(iB) = circ_cmtest(PPC.Pdist, PPCboot.Pdist);
        pcompww(iB) = circ_wwtest(PPC.Pdist, PPCboot.Pdist);
        warning on
        % This implementation is REDICULOUSLY SLOW!!!! 
        pcompwu(iB) = watsons_U2_approx_p(PPC.Pdist, PPCboot.Pdist); % a few papers show that this is superior to most other 2-sample tests.
        %         Phsamp = interp1(TuS_PHASE(:,1), TuS_PHASE(:,2),Tsamp{iB}, 'nearest');
        %         Tdist = pdist(Tsamp(:));
        %         GIX = Tdist > min_skip_time_uS;
        % Use pdist and circ_dist to compare all possible combinations in phase distance and time distance.
        %         Pdist_boot = pdist(Phsamp(:), @circ_dist);
        %%%%%
        %         [~, zboot(iB)] = circ_rtest(Pdist_boot(GIX));
    end
    PPC.p_to_boot = 1-ksdensity(zboot,PPC.z ,'Support','positive', 'Function','cdf');
    PPC.z_to_boot = (PPC.z - nanmean(zboot))/std(zboot);
    figure
    histogram(zboot,100,'Normalization','pdf')
    hold on
    ksdensity(zboot,'Support','positive', 'Function','pdf')
    
end




if 0
    figure
    subplot(1,2,1)
    polarhistogram(Pdist)
    hold on
    polarhistogram(Pdist(gix))
    subplot(1,2,2)
    histogram(zboot)
    title(sprintf('z = %f', PPC.z))
end
