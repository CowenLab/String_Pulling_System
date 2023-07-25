function [C,fq,T] = Spectrogram_spindle(raw_lfp, sFreq, Fqs_to_plot)
%function [C,fq,new_x_msec] = Spectrogram_ripple(raw_lfp, sFreq, Fqs_to_plot)
%% Makes a spectrogram tailored to ripples (given the higher fq and sampling rate)
% INPUT: raw lfp vector. 
%        sampling rate of the data.
%        vector of frequencies to plot.
% 
% Cowen 2015
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
window = 32; % 64 this seems to be ideal for 200Hz sFreq ripples.
overlap = 28; % 56 this seems to be ideal for 1800Hz sFreq ripples.

if nargin < 3
    Fqs_to_plot = 1:.2:50;
end

if length(raw_lfp) <= window
    disp('too few points to do spectrogram')
    C = []; fq = [];
    return
end

%
[~,fq,T,P] = spectrogram(raw_lfp,window,overlap,Fqs_to_plot,sFreq);
C = 10*log10(abs(P)); % From the matlab docs.
% The convolution can make it prettier - may lose info though
% Cs = conv_filter(C',hanning(10)/sum(hanning(10)))';
% figure
% subplot(1,2,1)
% imagesc(T*1000,fq,C)
% subplot(1,2,2)
% imagesc(T*1000,fq,Cs)

if nargout == 0 
    cla
    imagesc(T*1000,fq,C)
    axis tight;
    axis xy
    ylabel ('Hz');xlabel('ms')
    plot_vert_line_at_zero(0,3,'w')
    pubify_figure_axis
end
