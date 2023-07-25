function [C,fq,T] = Spectrogram_ripple(raw_lfp, sFreq, Fqs_to_plot, type)
%function [C,fq,new_x_msec] = Spectrogram_ripple(raw_lfp, sFreq, Fqs_to_plot)
%% Makes a spectrogram tailored to ripples (given the higher fq and sampling rate)
% INPUT: raw lfp vector.
%        sampling rate of the data.
%        vector of frequencies to plot.
%
% Cowen 2015
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
window = 64; % 64 this seems to be ideal for 1800Hz sFreq ripples.
overlap = 56; % 56 this seems to be ideal for 1800Hz sFreq ripples.
if nargin < 4
    type = 'wavelet';
end
if nargin < 3
    Fqs_to_plot = 70:2:280;
end

% if sFreq < 1500
%     disp('Optimized for 1800 Hz - may need tweaking for other sFreq')
% end

% if length(raw_lfp) <= window
%     window = 32;
%     overlap = 30;
% end

if length(raw_lfp) <= window
    disp('too few points to do spectrogram')
    C = []; fq = [];
    return
end


if nargin == 0
    % If the user passes nothing in, do a test.
    % chirp for testing.
    sFreq = 1800;
    interval_s = 1/sFreq;
    t = 0:interval_s:0.800;
    fo = 80; f1 = 300;     % Frequency - linear increase from f0 to f1
    raw_lfp = chirp(t,fo,t(end),f1);
end
%
switch type
    case 'fft'
        % this is OK but can give strange results for some ripples. Wavelet
        % seems to be more accutate and has a higher peak
        [~,fq,T,P] = spectrogram(raw_lfp,window,overlap,Fqs_to_plot,sFreq);
        C = 10*log10(abs(P)); % From the matlab docs.
    case 'wavelet'
        [C,fq] = SPEC_cwt_cowen(raw_lfp,sFreq,Fqs_to_plot,32);
        C = (abs(C)).^2;
        %         if length(Fqs_to_plot) > 2
        %             C = interp1_matrix(fq,C, Fqs_to_plot,'spline');
        %             fq = Fqs_to_plot;
        %         end
        
        T = linspace(0,length(raw_lfp)/sFreq,Cols(C));
end

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
    ylabel ('Hz');xlabel('ms')
    %     plot_vert_line_at_zero(0,3,'w')
    pubify_figure_axis
    colormap(jet)
    axis xy
end
