function Params = filter_test(cutoff_or_bandpass_Fq, FiltOrder, sFreq, high_stop_bandpass_or_low, Ripple)
%%%%%%%%%%%%%%%%%%%%%%%%%
%% Params = filter_test(cutoff_or_bandpass_Fq, FiltOrder, sFreq, high_stop_bandpass_or_low, Ripple)
%% test a filter and return the parameters.
%%%%%%%%%%%%%%%%%%%%%%%%%
Nq = sFreq/2;
% For the yulewalk filter.
F_range = 0:.001:1;
idx_low = find(F_range>=min(cutoff_or_bandpass_Fq/Nq));
idx_high = find(F_range>=max(cutoff_or_bandpass_Fq/Nq));
idx_low = idx_low(1);
idx_high = idx_high(1);

M = zeros(size(F_range));
if (idx_low == idx_high)
    switch high_stop_bandpass_or_low
    case 'high'
        M = zeros(size(F_range));
        M(idx_low:end) = 1;
    case 'low'
        M = zeros(size(F_range));
        M(1:idx_low) = 1;
    case 'bandpass'
        M(idx_low:idx_high) = 1;
    end
end

[Params.Yb, Params.Ya] = yulewalk(FiltOrder, F_range , M); % This is best for MULTI-Band (more than one band) filters.
[Params.Bb, Params.Ba] = butter  (FiltOrder, cutoff_or_bandpass_Fq/Nq       , high_stop_bandpass_or_low);
[Params.Cb, Params.Ca] = cheby1  (FiltOrder, Ripple,cutoff_or_bandpass_Fq/Nq, high_stop_bandpass_or_low);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show it's response propertiess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[Yfr, F] = freqz(Params.Yb , Params.Ya , 512 , sFreq); % h = the frequency response. I really don't understand the 256 part.
[Bfr, F] = freqz(Params.Bb , Params.Ba , 512 , sFreq); % h = the frequency response. I really don't understand the 256 part.
[Cfr, F] = freqz(Params.Cb , Params.Ca , 512 , sFreq); % h = the frequency response. I really don't understand the 256 part.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Normalize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Yfr = abs(Yfr);
Bfr = abs(Bfr);
Cfr = abs(Cfr);
Yfr(isinf(Yfr)) = -.1;
Bfr(isinf(Bfr)) = -.1;
Cfr(isinf(Cfr)) = -.1;
Yfr = Yfr/max(Yfr);
Bfr = Bfr/max(Bfr);
Cfr = Cfr/max(Cfr);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For some reason, h is sinusoidal so you need to take the abs to get the tuning response.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure
plot(F , Yfr , F , Bfr , F , Cfr)
grid on
legend('yulewalk','butter','cheby1')
xlabel('Frequency')
title(['Filter Order ' num2str(FiltOrder) ' ' high_stop_bandpass_or_low ' Neg val = inf'])
