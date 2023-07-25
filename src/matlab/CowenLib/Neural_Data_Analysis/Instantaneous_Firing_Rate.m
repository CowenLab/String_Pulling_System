function [Q,Qsmth,bin_edges,IF,Qsh] = Instantaneous_Firing_Rate(T, binsize, smooth_bins, varargin)
% IFR
% iF YOU WANT THIS TO BE SECONDS, BE SURE T AND BINSIZE IS IN SECONDS
% See Goldberg, J.H., Adler, A., Bergman, H., Fee, M.S., 2010. Singing-related neural activity distinguishes two putative pallidal cell types in the songbird basal ganglia: Comparison to the primate internal and external pallidal segments. J. Neurosci. 30, 7088–7098. https://doi.org/10.1523/JNEUROSCI.0168-10.2010
% where ti is the time ofthe ith spike. To compute the power spectra ofthe IFRs, IFR signals were mean-subtracted and multiplied by a Hanning window before calculating the fast Fourier transform.
%
% T = cumsum(abs(randn(1000,1)*.1)+.004); binsize = .010; % assume seconds
% smooth_bins = 10;
% Been crashing
T = T(~isnan(T));
PLOT_IT = false;
start_time = T(1);
end_time = T(end);

Extract_varargin

% SPEED_IT = true;
%%
spk_sFreq = length(T)/(T(end)-T(1));

bin_edges = start_time:binsize:(end_time+eps);
bin_edges = bin_edges(:);
Q = zeros(length(bin_edges)-1,1);

r = 1./diff(T);
% the following is inefficient - this potentially could be made MUCH more
% efficient.
for iT = 1:(length(T)-1)
    IX = bin_edges > T(iT) & bin_edges <= T(iT+1);
    Q(IX) = r(iT);
end
Q = Q(1:length(bin_edges)-1);
tmp = hanning(smooth_bins*2);
tmp(1:smooth_bins) = 0;
ker = tmp;
% ker = hanning(smooth_bins);
ker = ker/sum(ker); % norm so that units are not weird.

% if nargout > 1
Qsmth = conv_filter(Q/mean(Q),ker);
% Get rid of DC
mn_seg = 4;
% Qsmth = Qsmth - movmean(Qsmth,[round(length(Q)/mn_seg),0]);

% end
if nargout > 3
    % determine the IFR for each spike...
    ctrs = bin_edges(1:end-1) + mean(diff(bin_edges))/2;
    IF = interp1(ctrs,Qsmth,T,'linear');
end

if nargout > 4 || PLOT_IT
    Tsh = Shuffle_ISIs(T);
    
    rsh = 1./diff(Tsh);
    
    Qsh = zeros(length(bin_edges)-1,1);
    for iT = 1:(length(T)-1)
        
        IX = bin_edges > Tsh(iT) & bin_edges <= Tsh(iT+1);
        Qsh(IX) = rsh(iT);
    end
    Qsh = Qsh(1:length(bin_edges)-1);
    
    Qsmth_sh = conv_filter(Qsh/mean(Qsh),ker);
    Qsmth_sh = Qsmth_sh - movmean(Qsmth_sh,[round(length(Q)/mn_seg),0]);
end

if PLOT_IT
    xs = bin_edges(1:end-1)+binsize/2;
    sFreq = 1/binsize;
    figure
    subplot(4,2,1:2)
    plot(xs,Q)
    hold on
    axis tight
    a = axis;
    plot(T,ones(size(T))*a(4),'k+')
    yyaxis right
    plot(xs,Qsmth,'Color',[.8 .2 .2])
    axis tight
    pubify_figure_axis
    title(sprintf('%2.1f Hz, LV=%2.1f',spk_sFreq, LocalVariance(diff(T))));
    
    subplot(4,2,3)
    HistISI(T*10000);
    subplot(4,2,4)
    [ac,x] = AutoCorr(T*10000,2,100);
    [ac_sh,x] = AutoCorr(Tsh*10000,2,100);
    
    plot(x,ac,'b',x,ac_sh,'k')
    
    xlabel('ms')
    subplot(4,2,5)
    pwelch(Q,sFreq*3,sFreq,[],sFreq)
    hold on
    pwelch(Qsh,sFreq*3,sFreq,[],sFreq)
    h = gca;
    h.Children(2).Color = [0 0 0];
    subplot(4,2,6)
    pwelch(Qsmth,sFreq*3,sFreq,[],sFreq)
    hold on
    pwelch(Qsmth_sh,sFreq*3,sFreq,[],sFreq)
    h = gca;
    h.Children(2).Color = [0 0 0];
    
    subplot(4,2,7)
    spectrogram(Q,sFreq*3,sFreq,256,sFreq,'yaxis')
    subplot(4,2,8)
    spectrogram(Qsmth,sFreq*3,sFreq,256,sFreq,'yaxis')
end