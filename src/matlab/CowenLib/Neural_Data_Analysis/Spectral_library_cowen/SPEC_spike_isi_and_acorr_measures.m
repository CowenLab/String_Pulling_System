function [OUT] = SPEC_spike_isi_and_acorr_measures(TS_uS, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT: TS_uS   cell array of action potential times.
% It is assumed these data have bene pre-selected so that they are from a
% consistent behavior (e.g., movement only, rest only...).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PLOT_IT = false;
nBins_log = 500;
up_lim_ac_ms = 200;
up_lim_isi_ms = 50;
binsize_ms = 2;
min_spikes = 30;
smth_bins = 11;
min_isi_ms = 2; % some boundary as ISIs < this value should be rediculous.
gamma_isi_range_ms = [1000/100 1000/35];

Extract_varargin;

ISI_edges_ms = 0:binsize_ms:up_lim_isi_ms;
ISI_gam_edges_ms = gamma_isi_range_ms(1):binsize_ms:gamma_isi_range_ms(end);
acorr_x_ms = 0:binsize_ms:up_lim_ac_ms;

OUT.acorr = nan(length(TS_uS),length(acorr_x_ms)-1);
OUT.acorr_smth = nan(length(TS_uS),length(acorr_x_ms)-1);

OUT.ISI_hist = nan(length(TS_uS),length(ISI_edges_ms)-1);
OUT.ISI_hist_x_ms = ISI_edges_ms(1:end-1) + (ISI_edges_ms(2) - ISI_edges_ms(1))/2;
OUT.ISI_gam_hist_x_ms = ISI_gam_edges_ms(1:end-1) + (ISI_gam_edges_ms(2) - ISI_gam_edges_ms(1))/2;

OUT.acorr_x_ms = [];
min_isi = nan(length(TS_uS),1);
max_isi = nan(length(TS_uS),1);
OUT.acorr_peak_ms = nan(length(TS_uS),1);
OUT.acorr_peak_Hz = nan(length(TS_uS),1);
OUT.ISI_gamma_std = nan(length(TS_uS),1);
OUT.ISI_gamma_fano = nan(length(TS_uS),1);

for iN = 1:length(TS_uS)
    TS_uS{iN} = unique(TS_uS{iN});
    if ~isempty(TS_uS{iN})
        GIX = [ true ; diff(TS_uS{iN}/1000) > min_isi_ms];
        TS_uS{iN} = TS_uS{iN}(GIX);
    end
end

ISI = [];
for iN = 1:length(TS_uS)
    ISI_ms{iN} = [];
    if length(TS_uS{iN})>min_spikes
        ISI_ms{iN} = diff(TS_uS{iN})/1e3;
        min_isi(iN) = min(ISI_ms{iN});
        max_isi(iN) = max(ISI_ms{iN});
        %         [a, OUT.acorr_x_ms] = AutoCorr(TS_uS{iN}/1000,binsize_ms,length(acorr_x_ms)-1);a = a';
        
        [a, OUT.acorr_x_ms] = Auto_corr(TS_uS{iN}/1000,binsize_ms,length(acorr_x_ms)-1,'scaleopt','coeff');
        OUT.acorr(iN,:) = a;
        OUT.acorr_smth(iN,:) = sgolayfilt(OUT.acorr(iN,:),3,smth_bins);
        [~,ix] = nanmax(OUT.acorr_smth(iN,:));
        OUT.acorr_peak_ms(iN) = OUT.acorr_x_ms(ix);
        OUT.acorr_peak_Hz(iN) = 1000/OUT.acorr_x_ms(ix);
        %         [p,i] = findpeaks(OUT.acorr_smth(iN,:));
    end
end

ISI_edges_log_ms = logspace(log10(min(min_isi)),log10(1000),nBins_log);

for iN = 1:length(TS_uS)
    if ~isempty(ISI_ms{iN})
        [OUT.ISI_hist(iN,:)] = histcounts(ISI_ms{iN},ISI_edges_ms);
        [OUT.ISI_log10_hist(iN,:),OUT.ISI_log10_ms] = histcounts(log10(ISI_ms{iN}),ISI_edges_log_ms);
        % just for gamma
        GIX = ISI_ms{iN} >= gamma_isi_range_ms(1) & ISI_ms{iN} <= gamma_isi_range_ms(2);
        if sum(GIX) > 10
            ISI_ms_gamma{iN} = ISI_ms{iN}(GIX);
            [OUT.ISI_hist_gamma(iN,:)] = histcounts(ISI_ms_gamma{iN},ISI_gam_edges_ms);
            OUT.ISI_gamma_std(iN) = std(ISI_ms{iN}(GIX));
            OUT.ISI_gamma_fano(iN) = Fano_factor(ISI_ms{iN}(GIX));
        end
    end
end
OUT.ISI_log10_ms = OUT.ISI_log10_ms(1:end-1);


if PLOT_IT
    figure
    subplot(1,3,1:2)
    bar(OUT.acorr_peak_Hz)
    hold on
    plot_horiz_line_at_zero(1000/gamma_isi_range_ms(1))
    plot_horiz_line_at_zero(1000/gamma_isi_range_ms(2))
    ylabel('Hz')
    subplot(1,3,3)
    histogram(OUT.acorr_peak_Hz,80)
    
    
    figure
    bar(OUT.ISI_gamma_fano)
    
    figure
    subplot(2,1,1)
    imagesc(OUT.acorr_x_ms,[],OUT.acorr);
    subplot(2,1,2)
    plot_confidence_intervals(OUT.acorr_x_ms, OUT.acorr)
    xlabel('ms')
    
    figure
    subplot(2,1,1)
    imagesc(OUT.ISI_hist_x_ms,[],OUT.ISI_hist);
    subplot(2,1,2)
    plot_confidence_intervals(OUT.ISI_hist_x_ms, OUT.ISI_hist)
    xlabel('ms')
    
    for iN = 1:length(TS_uS)
        if length(TS_uS{iN})>min_spikes
            figure(iN)
            
            subplot(2,2,1)
            plot(OUT.acorr_x_ms,OUT.acorr(iN,:));
            hold on
            plot(OUT.acorr_x_ms,OUT.acorr_smth(iN,:));
            title('acorr');
            xlabel('ms')
            
            subplot(2,2,2)
            plot(OUT.ISI_hist_x_ms,OUT.ISI_hist(iN,:));
            title('ISI hist')

            subplot(2,2,3)
            plot(OUT.ISI_log10_ms,OUT.ISI_log10_hist(iN,:));
            title('Log ISI hist')
            xlabel('ms')
            
            subplot(2,2,4)
            plot(OUT.ISI_gam_hist_x_ms,OUT.ISI_hist_gamma(iN,:));
            title('gamma ISI hist')
            xlabel('ms')
            
            
        end
    end
end


