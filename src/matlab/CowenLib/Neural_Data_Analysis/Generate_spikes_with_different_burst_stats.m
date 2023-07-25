function [t_sec, lv] = Generate_spikes_with_different_burst_stats(wts, exponent, mean_freq, n_sec_stim, min_isi_s)
% Generate ISIs
% wts = [0 1 0];
% mean_freq = 20;
% n_sec_stim = 2;
n_pulses = n_sec_stim*mean_freq;
% exponent = 2.8; % 1.8 is approximately LV = 1.6.
% pull an ISI from the distribution with thisi probablity.
STIM = zeros(1,n_pulses-1);
% Could make an array of functions = would generalize better.
%
for ii = 1:(n_pulses-1)
    v = rand(1,length(wts)).*wts;
    [~,choice] = max(v);
    switch choice
        case 1 % Fixed
            STIM(ii) = 1/mean_freq;
        case 2 % Poisson
            STIM(ii) = exprnd(1/mean_freq,1);
            while STIM(ii) < min_isi_s
                STIM(ii) = exprnd(1/mean_freq,1);
            end
        case 3 % Burst
            STIM(ii) = exprnd(1/mean_freq,1)^exponent;
            while STIM(ii) < min_isi_s
                STIM(ii) = exprnd(1/mean_freq,1)^exponent;
            end
            %             STIM(ii) = random('Logistic',1/mean_freq,1/mean_freq,1,1);
    end
end
% Ensure the mean rate is correct. Shrink or expand the ISIs to make it
% correct.
fctr = (1/mean_freq)/mean(STIM);
STIM = STIM*fctr;
t_sec = [0 cumsum(STIM)];
lv = LocalVariance(diff(t_sec(:)));

%
if nargout == 0
    figure(1)
    subplot(2,1,1)
    hold on
    histogram(STIM,[0:.005:.25])
    title(['LV ' num2str(lv)])
    xlabel('ISI (s)')
    subplot(2,1,2)
    hold on
    plot_raster(t_sec,find(wts==1,1,'first'),'LineWidth',.1)
    % plot(t_sec,ones(size(t_sec))*find(wts==1,1,'first'),'.')
    axis tight
    xlabel('s')
end