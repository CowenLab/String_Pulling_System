function [OUT] = SPEC_gamma_event_detection_dvorak2014(DATA, sFreq, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WORK IN PROCESS
% INPUT: DATA  col 1= timestamps (assumes uS) , col 2 = unfiltered LFP
%        sFreq of the data
%        the data should be somewhat continuous - within reason
%        to deal with this, you can run this function on each trial
%        separately in a loop. Might be best.
%
% OUTPUT: timing of high and low gamma events and the LG, HG power.
%
% TODO: What did Dvorak do about denominators of zero and therefore
% infinite values? A ration will have this problem.
%
% See Dvorak D, Fenton AA. 2014. Toward a proper estimation of phase-amplitude coupling in neural oscillations. J Neurosci Methods [Internet] 225:42–56. Available from: http://www.ncbi.nlm.nih.gov/pubmed/24447842
% Also see Dvorak D, Radwan B, Sparks FT, Talbot ZN, Fenton AA. 2018. Control of recollection by slow gamma dominating mid-frequency gamma in hippocampus CA1. PLoS Biol 16:1–27.
% Calculation of instantaneous SG/MG ratio. First, we extracted band-specific oscillatory
% Oscillation rates (Fig. 1A, lower) are computed as the number of detected events in a representative frequency range (30-50 for CA1 slow gamma, 70-90 Hz for CA1 mid-frequency gamma) in a 1-s window advanced by 0.25 s and smoothed using 2.5 s moving average. SG/MG ratio (Fig. 1A, lower) is computed as a ratio of CA1 slow gamma oscillation rate and CA1 mid-frequency gamma oscillation


% Notes from Fenton...
% Dear Stephen,
% Thanks for great email. It makes me really happy to learn that the talk motivated you to try event-based analyses. I am sorry for getting to it so late; it simply got buried in my inbox.
% Those are pretty convincing differences. Cool. The effect is actually very big.
% 
% As for you questions, We never have 0 MG in the 2.5 s windows. In fact the assessment and smoothing windows are set in part to avoid this. Importantly, there is a LFP preprocessing “quality step” prior to any analysis during which we remove from analysis data that we think are contaminated by artifacts. We tend to make long recordings so can be very stringent in this step, and only accept for analysis artifact free data segments that are “long enough”, typically we pick 4 s as long enough.
% 
% We also chose the SG/MG ration because there is so much more MG. If you are getting MG=0 or even very low then I wold suggest to look at those segments and make sure they are not artifacts like a saturation or v=0 recovery from saturation etc. Then decide what to do. If there is legitimately MG=0 I would initially ignore the segments. Eventually you might want to investigate a SG/(SG+MG) ration to figure out it is distributed relative to SG/MG. We went wit SG/MG because it is easy to interpret.
% 
% We like to pick equivalent random segments from the data as a control and to test specific hypotheses like speed, SWR being responsible for any findings we just segment the data and make the comparisons when those parameters are low and high. We like to call this "behavior clamping”  and it is essentially testing the subsampled extremes of your correlation with the middle excluded.
% 
% Keep in touch and happy weekend,
% André

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PLOT_IT = false;
sig_power_percentile = 95; % In one paper, Dvorak uses 99th percentile so much higher than this.
sig_power_sd = 2.5; % Dvorak uses 2.5 sd. This is what we use here.
low_med_gamma = [30 50;70 90]; % definition of low and medium gamma bands.
wideband_gamma = [low_med_gamma(1)-10 low_med_gamma(end)+20]; % for plotting the entire range.
han_size = 12; % works well - too small and you get false negatives for peak detection.

Extract_varargin;

psd_fqs = wideband_gamma(1):.5:wideband_gamma(end);

OUT.psd_fqs = psd_fqs;
OUT.low_med_gamma = low_med_gamma;
OUT.sig_power_percentile = sig_power_percentile;

% Convert data to z scores
DATA(:,2) = (DATA(:,2)-nanmean(DATA(:,2)))/nanstd(DATA(:,2));

pw = SPEC_cwt_cowen(DATA(:,2),sFreq, psd_fqs);
pw = abs(pw).^2./(std(pw,[],2).^2); % From Dvorak and Fenton - definition of power.
mn_psd = trimmean(pw(:,1:10:end),99,2); % Trim in case of wacko artifacts. This works, but median does not at some frequencies - where power is lower. Not sure why.
sd_psd = trimstd(pw(:,1:10:end),[.5 99.5],2); %
pw = (pw - mn_psd)./sd_psd;
pwth = pw;
pwth(pwth < sig_power_sd) = 0;
% Smooth to ensure that there is only one peak...
han = hanning(han_size)*hanning(han_size)';
han = han/sum(han(:));
% pwths = convn(pwth,han,'same');
% problem with FastPeakFind is that it MISSES A LOT- false negatives if your convolution kernel is too small.
% hanning(12) seems to work well.
cent = FastPeakFind(pwth,sig_power_sd,han);
ic = cent(1:2:end); ir = cent(2:2:end);
% figure;imagesc(pwth);hold on; plot(ic,ir,'yo');plot(ic,ir,'r+'); axis xy ; caxis([2.5 7]);colorbar

BIX = psd_fqs(ir) >= low_med_gamma(end) | psd_fqs(ir) <= low_med_gamma(1);
ic = ic(~BIX); ir = ir(~BIX);
ic_orig = ic; ir_orig = ir; % for plotting and debugging

% figure;imagesc(pwth);hold on; plot(ic,ir,'yo');plot(ic,ir,'r+'); axis xy ; caxis([2.5 7]);colorbar
% remove peaks that are adjacent to one another.
dist = squareform(pdist([ir(:) ic(:)]));
D = upper_diag(dist);
% remove peaks that are within 5 points of each other (for spurious double
% peaks or peaks following 'ridges'). 
BIX = sum(D < sqrt(25+25)+eps) > 0;
ic(BIX) = []; ir(BIX) = [];
% plot(ic,ir,'co');plot(ic,ir,'g+')

ind = sub2ind(size(pwth),ir,ic);
powers = pwth(ind);
if 0
    % figure;imagesc(pwths);hold on; plot(ic,ir,'yo'); axis xy ; caxis([1.5 10]);colorbar
    figure; histogram(psd_fqs(ir),30); xlabel('Hz');
    figure; plot(powers,psd_fqs(ir),'.')
end
SGIX = psd_fqs(ir) <= low_med_gamma(1,2);
MGIX = psd_fqs(ir) >= low_med_gamma(2,1);

SG_times = DATA(ic(SGIX),1);
MG_times = DATA(ic(MGIX),1);
end_time = max([SG_times; MG_times]);
edges_uS = DATA(1,1):.25e6:end_time;
SGx = histcounts(SG_times,edges_uS);
MGx = histcounts(MG_times,edges_uS);
SG = movsum(SGx,10); % 10 bins = 2.5 seconds. Same as Dvorak.
MG = movsum(MGx,10);
ALL_ZERO_BIX = SG == 0 & MG == 0;
ANY_ZERO_BIX = SG == 0 | MG == 0;
% the problem with the following is that it generates inf for MG with zero
% counts. How to address - the most fair way is probably to ignore any
% binse where there are either no SG or MG events. Alternatively, set the
% ratio to a reasonable 2 if there are infinities.
SGMGratio = SG./MG;
SGMGratio(ALL_ZERO_BIX) = nan; % There were no observations.
% OUT.SGMG_mean_ratio = nanmean(SGMGratio); % this does not work due to infinities.
OUT.SGMG_mean_ratio = nanmean(SGMGratio(~ANY_ZERO_BIX)); % Criteria that there has to be at least one MG or SG event to consider the ratio.
v = SGMGratio;
v(isinf(v)) = 2;
OUT.SGMG_mean_ratio_inf_to_2 = nanmean(v);

% SGMGratio(isinf(SGMGratio)) = nan;

%SG
GIX = psd_fqs >= low_med_gamma(1,1) & psd_fqs <= low_med_gamma(1,2);
mean_SG_pow = mean(nanmean(pwth(GIX,:),2));
mean_SG_abv = mean(nanmean(pwth(GIX,:)>0,2));
%MG
GIX = psd_fqs >= low_med_gamma(2,1) & psd_fqs <= low_med_gamma(2,2);
mean_MG_pow = mean(nanmean(pwth(GIX,:),2));
mean_MG_abv = mean(nanmean(pwth(GIX,:)>0,2));
% Some extra measures (NOT IN THE Dvorak papers so use with caution)
OUT.SGMG_power_ratio = mean_SG_pow/mean_MG_pow;
OUT.SGMG_abv_th_ratio = mean_SG_abv/mean_MG_abv;


OUT.bin_centers_uS = edges_uS(1:end-1)+ .75e6;

OUT.SG = SG;
OUT.MG = MG;

norm_ratio = (SG-MG)./(SG+MG);
norm_ratio(ALL_ZERO_BIX) = nan;

OUT.SGMG_ratio_norm = norm_ratio;
OUT.SGMG_mean_ratio_norm = nanmean(norm_ratio); % positive means more SG, negative means more MG

OUT.SGMG_ratio = SGMGratio;
OUT.SGdom = SGMGratio>1.0001; % Sg dominant events (from paper - DG spike paper and 2018 paper)


OUT.All_times_uS = DATA(ic,1);
OUT.SG_times_uS = SG_times;
OUT.MG_times_uS = MG_times;
OUT.frequencies = psd_fqs(ir);
OUT.powers = powers;

if PLOT_IT
    %%
    x = linspace(0,Cols(pwth)/sFreq,Cols(pwth));
    figure
    subplot(2,4,1:3)
    % For figure in papaer
    imagesc(x,psd_fqs(:),pwth); axis xy;hold on; 
%     plot(ic,psd_fqs(ir),'yo');
%     plot(ic,psd_fqs(ir),'r+'); 
%     plot(ic_orig,psd_fqs(ir_orig),'c.');
    plot(x(ic(SGIX)),psd_fqs(ir(SGIX)),'w+','markersize',15,'linewidth',2);
    plot(x(ic(MGIX)),psd_fqs(ir(MGIX)),'w+','markersize',15,'linewidth',2);
    plot(x(ic(SGIX)),psd_fqs(ir(SGIX)),'yo','markersize',15,'linewidth',2);
    plot(x(ic(MGIX)),psd_fqs(ir(MGIX)),'yo','markersize',15,'linewidth',2);
    axis xy ; caxis([2.5 5]);colorbar
    a = axis;
    plot(a(1:2),[low_med_gamma(1,1) low_med_gamma(1,1) ],'w:','Linewidth',1)
    plot(a(1:2),[low_med_gamma(1,2) low_med_gamma(1,2) ],'w:','Linewidth',1)
    plot(a(1:2),[low_med_gamma(2,1) low_med_gamma(2,1) ],'w:','Linewidth',1)
    plot(a(1:2),[low_med_gamma(2,2) low_med_gamma(2,2) ],'w:','Linewidth',1)
    xlabel('sec')
    ylabel('Hz')
    % set(gcf,'Position',[  -0.6        473.8       1180.8        385.2])
    subplot(2,4,4)
    histogram(psd_fqs(ir),30); xlabel('Hz');
    
    
    subplot(2,4,5:7)
    plot(OUT.bin_centers_uS /60e6, SG)
    hold on
    plot(OUT.bin_centers_uS /60e6,MG)
    yyaxis right
    plot(OUT.bin_centers_uS /60e6,SGMGratio)
    xlabel('min')
    legend('SG','MG','SGMGrat')
    axis tight
    subplot(2,4,8)
    histogram(log10(SGMGratio(SGMGratio>0)))
    xlabel('log ratio')
    plot_vert_line_at_zero()
end