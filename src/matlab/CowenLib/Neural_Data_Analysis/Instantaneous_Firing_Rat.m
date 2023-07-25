function [Q,Qs] = Instantaneous_Firing_Rat(T, binsize, smooth_bins,PLOT_IT)
% IFR
% iF YOU WANT THIS TO BE SECONDS, BE SURE T AND BINSIZE IS IN SECONDS
% See Goldberg, J.H., Adler, A., Bergman, H., Fee, M.S., 2010. Singing-related neural activity distinguishes two putative pallidal cell types in the songbird basal ganglia: Comparison to the primate internal and external pallidal segments. J. Neurosci. 30, 7088–7098. https://doi.org/10.1523/JNEUROSCI.0168-10.2010
% where ti is the time ofthe ith spike. To compute the power spectra ofthe IFRs, IFR signals were mean-subtracted and multiplied by a Hanning window before calculating the fast Fourier transform.
%
% T = cumsum(abs(randn(1000,1)*.1)+.004); binsize = .010; % assume seconds
% smooth_bins = 10;
if nargin < 4
    PLOT_IT = false;
end

%%
bin_edges = T(1):binsize:(T(end)+eps);
bin_edges = bin_edges(:);
Q = zeros(length(bin_edges)-1,1);
d = diff(T);
r = 1./d;
for iT = 1:(length(T)-1)
    IX = bin_edges > T(iT) & bin_edges <= T(iT+1);
    Q(IX) = r(iT);
end
Q = Q(1:length(bin_edges)-1);
% if nargout > 1
Qs = conv_filter(Q/mean(Q),hanning(smooth_bins)/sum(smooth_bins));
% end

if PLOT_IT
    xs = bin_edges(1:end-1)+binsize/2;
    sFreq = 1/binsize;
    figure
    subplot(4,2,1:2)
    plot(xs,Q)
    hold on
    axis tight
    a = axis;
    plot(T,ones(size(T))*a(4),'r+')
    yyaxis right
    plot(xs,Qs)
    axis tight
    subplot(4,2,3)
    HistISI(T*10000)
    subplot(4,2,4)
    [ac,x] = AutoCorr(T*10000,2,50);
    plot(x,ac)  
    xlabel('ms')
    subplot(4,2,5)
    pwelch(Qs,sFreq*3,sFreq,[],sFreq)
    subplot(4,2,7:8)
    spectrogram(Qs,sFreq*3,sFreq,256,sFreq,'yaxis')
end