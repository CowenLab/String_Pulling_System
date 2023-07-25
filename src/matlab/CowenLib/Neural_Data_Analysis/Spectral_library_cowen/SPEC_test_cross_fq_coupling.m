function [out] = SPEC_test_cross_fq_coupling()
% Test measures of cross-frequency coupling against test data that test
% various assumptions. For example, does CFC measure assymetry, true CFC,
% etc...
% One of the best papers out there that really tested things was Dupré la Tour T, Tallot L, Grabot L, Doyère V, van Wassenhove V, Grenier Y, et al. Non-linear auto-regressive models for cross-frequency coupling in neural time series [Internet]. Public Library of Science; 2017[cited 2018 Aug 1] Available from: http://dx.plos.org/10.1371/journal.pcbi.1005893

%% Step 1: Create artificial LFPs that have different flavors of CFC. Let's start with the basics
% Standard CFC. Oscillation riding on top of a sine wave.
addpath('C:\Users\Stephen Cowen\Box\Cowen Laboratory\Src_sub\matlab\LindseyCode\General_Time_Frequency')
close all
sFreq = 1500;
sig_duration_sec = 20;
% noise_factor = .01;
noise_factor = .08;
low_fq = 7;
n_cycles = sig_duration_sec*low_fq;
assym_factor = .05;
%  sig_type = 'classic_CFC_fixed_freq';
 sig_type = 'assymetry';
%  sig_type = 'no_CFC';
low_fqs = [2 4; 5 9; 11 14; 16 20; ];
high_fqs = [30 40; 50 60; 70 80; 90 100; 110 120];
nboot = 200;
fqs = 1:.25:140;

switch sig_type
    case 'no_CFC'
        
        x = linspace(0,2*pi*n_cycles,sFreq*sig_duration_sec);
        LFP = sin(x);
        LFP = LFP + randn(1,length(LFP))*noise_factor;
        
    case 'classic_CFC_vary_freq'
        % Create a frequency-varying slow oscillation
        % find the peaks
        % insert a gauspulse of the desired high frequency by centering it
        % on each peak.
        low_fq_mod_factor = 24.01;
        x = linspace(0,2*pi*n_cycles,sFreq*sig_duration_sec);
        % Create a random walk
        xrw = cumsum(randn(1,sFreq*sig_duration_sec));
        xrw = conv(xrw, hanning(sFreq)/sum(hanning(sFreq)),'same');
        xrw = standardize_range(xrw);
        xrw = xrw * low_fq_mod_factor;
        LFPlf = sin(x+xrw);
        % Find the peaks
        [~,pix] = findpeaks(LFPlf);
        x = linspace(0,sFreq/low_fq,round(sFreq/low_fq));
        newL = LFPlf;
        ang = angle(hilbert(LFPlf));
        for ii = 1:length(LFPlf )
            if LFPlf(ii) >.7
                newL(ii)= LFPlf(ii) + .2* sin(ang(ii)*4);
            end
        end
        
        LFP = newL;
        
    case 'classic_CFC_fixed_freq'
        % This is fixed frequecny so it's a terrible test of any CFC
        % measure that properly shuffles by time-shifting the data.
        % with fixed fixed frequency data, no
        % matter how you time-shift the surrogate, it will still
        % phase lock and kill CFC. As a result, a better artifical LFP
        % trace has continuously changing frequencies wihtin a range.
        high_fq = 95;
        hf_mod_factor = .4;
        phase_on_low_fq = pi*1.1;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        phase_angle_per_hf_cycle = 2*pi/(high_fq/low_fq);
        %         rad2deg(phase_angle_per_hf_cycle)
        % Let's just create one cycle.
        x = linspace(0,2*pi,sFreq/low_fq);
        xhf = linspace(0,2*pi*high_fq/low_fq,length(x));
        LFPlf = sin(x);
        LFPlf_mod = sin(x+phase_on_low_fq);
        LFPlf_mod(LFPlf_mod<0) = 0;
        hn = hanning(round(length(LFPlf_mod)/5));
        LFPlf_mod = cconv(LFPlf_mod,hn'/sum(hn),length(LFPlf_mod));
        LFPhf = sin(xhf);
        LFP_one_cycle = LFPlf + hf_mod_factor*LFPhf.*LFPlf_mod;
        LFP = repmat(LFP_one_cycle(1:end-1),1,n_cycles);
        LFP = LFP + randn(1,length(LFP))*noise_factor;
        figure
        subplot(3,1,1)
        plot(x,LFPlf,x,LFPhf,x,LFPlf_mod)
        subplot(3,1,2)
        plot(x,LFP_one_cycle)
        subplot(3,1,3)
        plot(LFP)
        
    case 'assymetry'
        npts = 2;
        T = low_fq*(1/npts)*sig_duration_sec;
        
        x = 0:1/sFreq:T-1/sFreq;
        y = sawtooth(2*pi*npts*x,assym_factor);
        y = y + randn(1,length(y))*noise_factor;
        hn = round(sFreq/4);
        LFP = conv(y,hanning(hn)/sum(hanning(hn)),'same');
        xx_in = linspace(0,sig_duration_sec,length(LFP));
        xx_out = linspace(0,sig_duration_sec,sFreq*sig_duration_sec);
        LFP = interp1(xx_in,LFP,xx_out);
        LFP = LFP + randn(1,length(LFP))*noise_factor;
        figure
        subplot 211
        plot(x,y)
        subplot 212
        plot(xx_out,LFP)
        
        %         v = polyfit(x,y,844);
        %         newY = polyval(v,x);
        %         clf
        
        
end
x_sec = linspace(0,sig_duration_sec,length(LFP));
%% %%%%%%%%%%%%%
% Add randomness to the frequencies...
% This adds some brownian drift diffusion like noise to each timestamp and
% then re-interpolates back to the original timestamps. I thought it was
% clever. Thought of it in the shower.
if 1
    xrw = cumsum(randn(1,length(x_sec)));
    xrw = conv(xrw, hanning(sFreq)/sum(hanning(sFreq)),'same');
    xrw = standardize_range(xrw);
    xrw = xrw * 900/sFreq;
    LFP2 = interp1(x_sec + xrw,LFP,x_sec);
    IX = isnan(LFP2);
    LFP2(IX) = nanmean(LFP);
    LFP = LFP2;
end

SPEC_plot_summary_spectral_info(LFP,fqs,sFreq)
% lf_filt = Filter_7hz(LFP, 5, 12, sFreq);
N = 8;
lf_filt = zeros(Rows(low_fqs),length(LFP));
hf_filt = zeros(Rows(high_fqs),length(LFP));
env_high = zeros(Rows(high_fqs),length(LFP));
[LFPpad,GIX] = SPEC_pad_signal(LFP,sFreq*4,'flipdata'); % I thought this would help, but no - not sure why - still edge effects.
% [LFPpad,GIX] = SPEC_pad_signal(LFP,sFreq*4,'zeros');

for ii = 1:Rows(low_fqs)
    bpFilt = designfilt('bandpassiir','FilterOrder',N, ...
        'HalfPowerFrequency1',low_fqs(ii,1),'HalfPowerFrequency2',low_fqs(ii,2), ...
        'SampleRate',sFreq,'DesignMethod' ,'butter');
    %     freqz(bpFilt,[],sFreq)
    tmp = filtfilt(bpFilt,LFPpad);
    lf_filt(ii,:) = tmp(GIX);
    figure
    plot((1:length(LFP))/sFreq,lf_filt(ii,:))
    
    
end

for ii = 1:Rows(high_fqs)
    bpFilt = designfilt('bandpassiir','FilterOrder',N, ...
        'HalfPowerFrequency1',high_fqs(ii,1),'HalfPowerFrequency2',high_fqs(ii,2), ...
        'SampleRate',sFreq,'DesignMethod' ,'butter');
    %     freqz(bpFilt,[],sFreq)
    tmp = filtfilt(bpFilt,LFPpad);
    hf_filt(ii,:) = tmp(GIX);
    env_high(ii,:) = envelope_cowen(abs(hf_filt(ii,:)));
    figure
    plot((1:length(LFP))/sFreq,hf_filt(ii,:))
    hold on
    plot((1:length(LFP))/sFreq,env_high(ii,:))
    
end
%%
for iL = 1:Rows(low_fqs)
    for iH = 1:Rows(high_fqs)
        hb_low = hilbert(lf_filt(iL,:));
        
        %            [pac(iH,iL), pacp(iH,iL), pacraw(iH,iL)] = SPEC_cross_fq_coupling_pac(angle(hb_low),env_high(iH,:),length(hb_low), 0, nboot,1);
           [pac(iH,iL), pacp(iH,iL), pacraw(iH,iL),pacz(iH,iL)] = SPEC_cross_fq_coupling_pac_no_window(angle(hb_low),env_high(iH,:),nboot,1);
        %              [pac(iH,iL), pacp(iH,iL), pacraw(iH,iL)] = SPEC_cross_fq_coupling_pac_no_window(angle(hb_low),env_high(iH,:),nboot,2);
        % Why does lindsey's code produce such HUGE z scores why does mine
        % produce such small ones.
%         [pac(iH,iL), pacp(iH,iL), pacraw(iH,iL),pacz(iH,iL)] = SPEC_cross_fq_coupling_pac_no_window_dpac(angle(hb_low)',env_high(iH,:)',nboot);
        
    end
end

figure
subplot(2,2,1:2)
plot((1:length(LFP))/sFreq, LFP)

subplot(2,2,3)
imagesc(pacz)
set(gca,'XTick',1:Cols(pac))
set(gca,'YTick',1:Rows(pac))
set(gca,'XTickLabel',mean(low_fqs,2))
set(gca,'YTickLabel',mean(high_fqs,2))
axis xy
colorbar
title('pacz')

subplot(2,2,4)
imagesc(real(pacraw))
set(gca,'XTick',1:Cols(pac))
set(gca,'YTick',1:Rows(pac))
set(gca,'XTickLabel',mean(low_fqs,2))
set(gca,'YTickLabel',mean(high_fqs,2))
axis xy
colorbar


figure
imagesc(pacp)
set(gca,'XTick',1:Cols(pac))
set(gca,'YTick',1:Rows(pac))
set(gca,'XTickLabel',mean(low_fqs,2))
set(gca,'YTickLabel',mean(high_fqs,2))
axis xy
colorbar
%%
figure;
SPEC_cross_fq_coupling_comod_dupre2017(LFP,sFreq,min(low_fqs(:)):.5:max(low_fqs(:)), 'canolty')
figure;
SPEC_cross_fq_coupling_comod_dupre2017(LFP,sFreq,min(low_fqs(:)):.5:max(low_fqs(:)), 'tort')
figure;
SPEC_cross_fq_coupling_comod_dupre2017(LFP,sFreq,min(low_fqs(:)):.5:max(low_fqs(:)), 'colgin')
figure;
SPEC_cross_fq_coupling_comod_dupre2017(LFP,sFreq,min(low_fqs(:)):.5:max(low_fqs(:)), 'bispectrum')
figure;
SPEC_cross_fq_coupling_comod_dupre2017(LFP,sFreq,min(low_fqs(:)):.5:max(low_fqs(:)), 'duprelatour')


