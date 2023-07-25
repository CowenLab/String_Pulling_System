function O = SPEC_plot_summary_spectral_info(sig, fqs, sFreq)
sig = real(sig);
subplot(2,2,1:2)
x = linspace(0,length(sig)/sFreq,length(sig));
plot(x,sig)
axis tight
subplot(2,2,3)
pwelch(sig,sFreq*4,sFreq/4,fqs,sFreq)
hold on
pburg(sig,211,fqs,sFreq)
pmtm(sig,[],fqs,sFreq)

subplot(2,2,4)
spectrogram(sig,sFreq*2,sFreq,fqs,sFreq,'yaxis')

