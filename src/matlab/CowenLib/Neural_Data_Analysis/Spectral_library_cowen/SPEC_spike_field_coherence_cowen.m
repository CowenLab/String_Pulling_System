function [OUT,OUTsh] = SPEC_spike_field_coherence_cowen(TS, DATA, sFreq, psd_fqs, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT: TS   cell array of action potential times.
%        OUT(iN).  col 1= timestamps in same units as TS, col 2 = unfiltered LFP
%        psd_fqs = the frequencies for the psd (e.g., 2:.5:180).
%        other parameters can be accessed through varargin.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This uses two approaches. The one I trust the most computes the wavelet
% for the LFP around each spike and extracts the PHASE at each timepoint so
% you get a nfrequencies, ntimepoints, nspikes matrix. For each nfreqxntime
% point you compute a circular z test (rayleigh z) to determine if the
% phase is consistent across events(spikes) and get a p value.
% This produces a nice 2d plot of z or p of freq x time around spike.
%
% To me, this is much improved over the approach described in chronux or inHalje P, Tamte M, Richter U, Mohammed M, Cenci MA, Petersson P. 2012. Levodopa-Induced Dyskinesia Is Strongly Associated with Resonant Cortical Oscillations. J Neurosci [Internet] 32:16541–16551. Available from: http://www.jneurosci.org/cgi/doi/10.1523/JNEUROSCI.3047-12.2012
% which computes the psd of the STA. I think it's much better because the
% STA AVERAGES away any consistent phase relationships due to fluctionation
% in amplitude or due to phase relationships at different frequencies that
% oppose/cancel out each other. My approach is not mine and is a very standard approahc and
%
% There are issues with spurious phase locking due to non-stationary or
% bursty spikes. To address this, this function also calculates the values
% using a shuffled distribution of spikes. Due to the time it takes to
% compute this, it is only done a few times or once (some more analyses suggest that it can be faster than thought - especially if I use the HPC). Ideally we would
% compute a null distributoin of circ z scores and measure how far our z
% score deviates from this but that would take a long time if you have a
% lot of spikes and frequencies.
%
% TODO: Should despike the LFP before the STA computation to eliminate
% spurious effects caused by bursts where one spike is regulalry followed
% by another. Currently, the second spike would still have it's artifact in
% the LFP. I have the code in comments right now but will need validation.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PLOT_IT = false;
min_spikes = 30; % you should have at least this many spikes to even consider statistical significance.
STA_window_pts = round(sFreq/2); % value used by Halje... these are the points before or after so the full window is 2 times this.
max_spikes = 2000; % if you have more than this, it's overkill for the stats so you might as well just subsample this value or less. This can save time/RAM if you have a lot of spikes.
time_bandwith_product = 3; % for pmtm - 3 is from Halje
shuffle = false; % do a shuffle control where you randomize the spikes as a sanity check.

Extract_varargin;

OUTsh = [];

if shuffle
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
    [OUTsh,INFO] = SPEC_spike_field_coherence_cowen(TSsh, DATA, sFreq, psd_fqs);
end
if ~iscell(TS)
    TS = {TS};
end
for iN = 1:length(TS)
    OUT(iN).STA_x_sec = [];
    OUT(iN).psd_fqs  = [];
    OUT(iN).circ_rtest_z = [];
    OUT(iN).circ_rtest_p = [];
    OUT(iN).circ_rtest_z_center = [];
    OUT(iN).circ_rtest_p_center = [];
    OUT(iN).STA_LFP  = [];
    OUT(iN).CWT_trial_by_trial_pow  = [];
    OUT(iN).CWT_of_STA  = [];
    OUT(iN).CWT_of_STA_psd  = [];
    OUT(iN).STA_pmtm_psd = [];
    OUT(iN).STA_pmtm_psd_norm = [];
    
end
% rid ourselves of spikes on the edge of the LFP so that the STA does not
% get confused by non-existent LFP for spikes on the edge.
TS = Restrict(TS,DATA(STA_window_pts+2,1),DATA(end-STA_window_pts-2,1));
% this can be sped up a LOT if the angle is computed at the front end
% [cwtpow,fqs]=SPEC_cwt_cowen(DATA(:,2),sFreq, psd_fqs, 32, 0);
% cwtang = single(angle(cwtpow));
% cwtpow = single(real(abs(cwtpow)));
% interp 4ms of points at center to get rid of spike artifact.
npts_spike = ceil(.004*sFreq);
cix = (STA_window_pts + 1 - npts_spike):(STA_window_pts + 1 + npts_spike);
GIX = true(1,STA_window_pts*2+1);
GIX(cix) = false;
sample_ix = [STA_window_pts - npts_spike - 1   STA_window_pts + 2 + npts_spike];
% sample_ix = [(STA_window_pts - npts_spike - 1):(STA_window_pts + 2 + npts_spike)];
peri_ix = [-40:-npts_spike npts_spike:40];

for iN = 1:length(TS)
    T = TS{iN};
    if length(T) < min_spikes
        continue
    end
    if length(T) > max_spikes
        disp([num2str(iN) ') ' num2str(length(T)) ' spikes, subsampling for efficiency to ' num2str(max_spikes) ' spikes'])
        T = unique(randsample(T,max_spikes,0));
    end
    % TODO: Remove the spikes from the data trhough interp..
    % DATA(:,3) = DATA(:,2); % 3rd col stores the data for now.
    % ix = binsearch_vector(DATA(:,1),T);
    % for i = 1:length(ix)
    % DATA(ix(i)-npts_spike:ix(i)+npts_spike,3) =
    % interp1(DATA(peri_ix + ix(i),1),DATA(peri_ix + ix(i),2),DATA(ix(i)-npts_spike:ix(i)+npts_spike,1),
    % 'spline')
    % end % now just need to send DAT(:,3) to PETH instead of 2.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Compute the sta
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [M,ix,OUT(iN).STA_x_sec]=PETH_EEG_simple(DATA, T,STA_window_pts,STA_window_pts,sFreq);
    OUT(iN).psd_fqs = psd_fqs;
    
    % interp 4ms of points at center to get rid of spike artifact.
    % Ideally, I would be able to compute pow and ang once before entering
    % the loop, but this would prevent me from inerpolating through the
    % spike - which is actually an issue I've found as you don't really
    % know if the LFP channel is picking up the neuron. If you DO know that
    % the neuron is not on the LFP, then this could be sped up A LOT by
    % computing the phase prior to entering this loop and allow for more
    % robust shuffle control as it would be sped up 100x. BUT WAIT - I can
    % use the data above for the shuffle control and speed things up 100x
    % as the spikes ARE SHUFFLED so the artifact is not an issue.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ANG = single(nan(length(psd_fqs),Cols(M), Rows(M)));
    POW = single(nan(length(psd_fqs),Cols(M), Rows(M)));
    POWpmtm = single(nan(Rows(M),length(psd_fqs)));
    for iM = 1:Rows(M)
        notNAN = ~isnan(M(iM,:));
        % the following should be eliminated once I pull spikes out of the
        % LFP prior (see TODO).
        M(iM,~GIX) = interp1(OUT(iN).STA_x_sec(GIX & notNAN),M(iM,GIX & notNAN),OUT(iN).STA_x_sec(~GIX),'spline');
        M(iM,:) = M(iM,:)-nanmean(M(iM,1:round(STA_window_pts/2))); % get rid of slow variation 
        cwt_data = SPEC_cwt_cowen(M(iM,:),sFreq, psd_fqs);
        POW(:,:,iM) = single(real(abs(cwt_data))); % cwt power at every time and frequency
        ANG(:,:,iM) = single(angle(cwt_data)); % phase angle at every time and frequency
        
        [POWpmtm(iM,:)] = pmtm(M(iM,:), time_bandwith_product, psd_fqs, sFreq);  % needed for the Halje/Fries approach.
    end
    OUT(iN).circ_rtest_z = single(nan(Rows(ANG),Cols(ANG)));
    OUT(iN).circ_rtest_p = single(nan(Rows(ANG),Cols(ANG)));
    
    for iR = 1:Rows(ANG)
        for iC = 1:Cols(ANG)
            [OUT(iN).circ_rtest_p(iR,iC),OUT(iN).circ_rtest_z(iR,iC)] = circ_rtest(squeeze(ANG(iR,iC,:)));
        end
    end
    OUT(iN).circ_rtest_z_center = mean(OUT(iN).circ_rtest_z(:,sample_ix),2,'omitnan');
    OUT(iN).circ_rtest_p_center = mean(OUT(iN).circ_rtest_p(:,sample_ix),2,'omitnan');
       
    OUT(iN).STA_LFP = nanmean(M)';
    OUT(iN).CWT_trial_by_trial_pow = nanmean(POW,3);
    
    % Wavelet spectrogram on the AVERAGE LFP response - this is going to be hampered by variance from trial to trial, but it's the way done in a Halje paper (but they use pmtm).
    [segpow]=  SPEC_cwt_cowen(OUT(iN).STA_LFP,sFreq, psd_fqs);
    %     segang = single(angle(segpow));
    segpow = single(real(abs(segpow)));
    OUT(iN).CWT_of_STA = segpow;
    OUT(iN).CWT_of_STA_psd = nanmean(segpow(:,sample_ix),2);
    
    [psdest] = pmtm(OUT(iN).STA_LFP,time_bandwith_product,psd_fqs,sFreq);
    %     [psdest] = pwelch(OUT(iN).STA_LFP,[],[],psd_fqs,sFreq);
    %     [psdest] = pburg(OUT(iN).STA_LFP,85,psd_fqs,sFreq);
    OUT(iN).STA_pmtm_psd = psdest; %abs(real(psdest));
    OUT(iN).STA_pmtm_psd_norm = (OUT(iN).STA_pmtm_psd.^2)./mean(POWpmtm.^2); % this is the Halje measure. ranges between 0 and 1, where 0 corresponds to the total absence of a phase relation between the spikes and the LFP component at frequency f, while 1 corresponds to the pres- ence of a perfect phase relation, i.e., all spikes occur at the exact same phase
end


if PLOT_IT
    %%
    p_th = 0.01;
    figure(101);clf
    figure(102);clf
    figure(103);clf
    
    for iN = 1:length(OUT)
        figure(101)
        subplot(ceil(length(OUT)/4),4,iN)
        plot( OUT(iN).STA_x_sec, OUT(iN).STA_LFP );
        axis tight
        title(num2str(iN));
        if iN == 1
            xlabel('sec')
        end
        box off

        figure(102)
        subplot(ceil(length(OUT)/4),4,iN)
        GIX = abs(OUT(iN).circ_rtest_p_center) < p_th;
        plot( OUT(iN).psd_fqs, OUT(iN).circ_rtest_z_center);
        hold on
        v = OUT(iN).circ_rtest_z_center;
        v(~GIX) = nan;
        plot( OUT(iN).psd_fqs, v,'r');
        if iN == 1
            ylabel('Spike phase coherence')
        end
        yyaxis right
        plot( OUT(iN).psd_fqs, OUT(iN).STA_pmtm_psd_norm);
        axis tight
        if iN == 1
            xlabel('Hz')
            ylabel('Halje measure')

        end
        title(num2str(iN));
        box off
        
        figure(103)
        subplot(ceil(length(OUT)/4),4,iN)
        Z = OUT(iN).circ_rtest_z;
        Z(OUT(iN).circ_rtest_p > p_th) = nan;
        imagesc(OUT(iN).STA_x_sec,OUT(iN).psd_fqs,Z)
        axis xy;
        title(num2str(iN));
        if iN == 1
            xlabel('sec')
            ylabel('Hz')
        end

    end
    
end
