function [Coeffs, scales, freq, SCImg, t] = Wavelet_ripple(sig, Fs, freqrange, scale_inc)
% function [Coeffs, scales, freq, SCImg, t] = Wavelet_ripple(sig, Fs, freqrange, scale_inc)
disp('DO NOT USE THIS - IT DOES STRANGE NONLINEAR THINGS TO THE FREQUENCY RESPONSE! LOOK AT WHAT IT DOES TO CHIRP')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% wavelet spectrogram tuned for ripples.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT: LFP data - a vectro
%        Fs - sampling rate.
%        freqrange - 2 element vector of range of frequencies.
% OUTPUT: Wavelet 
%        SCImg is the color plot with frequecy power. Not sure what the
%        units are.
%  - if no output, then it creates a pretty plot using wscalogram (a
%  wavelet toolbox function)
%
% Cowen 2014 - requires wavelet toolbox. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2
    % for testing
    Fs = 1800;
    interval_s = 1/Fs;
    t = 0:interval_s:0.800;
    fo = 80; f1 = 300;     % Frequency - linear increase from f0 to f1
    sig = chirp(t,fo,t(end),f1);
    freqrange = [50 260];
    scale_inc = 0.1;
    %
    %     wlen = 128;                        % window length (recomended to be power of 2)
    %     h = wlen/4;                         % hop size (recomended to be power of 2)
    %     nfft = 256;                        % number of fft points (recomended to be power of 2)
    %     [stft, f, t] = stft(sig, wlen, h, nfft, Fs);
    
end
if nargin < 3
    freqrange = [50 260];
end
if nargin < 4
    scale_inc = 0.2;
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SCImg = [];
wavetype = 'cmor1-1';
fc = centfrq(wavetype);
% a = fc/(freq*dt)
scalerange = fc./(freqrange*(1/Fs));
% With your scales of interest, obtain a scalogram analysis.
scales = scalerange(end):scale_inc:scalerange(1);

% Coeffs = cwt(sig,scales,wavetype,'plot');
Coeffs = cwt(sig,scales,wavetype);
imagesc([], freq ,S)

freq = scal2frq(scales,wavetype,1/Fs);
%
lensig = length(sig);
t = linspace(0,lensig/Fs,lensig);

if nargout >= 4
    S = abs(Coeffs.*Coeffs);
    SCImg = 100*S./sum(S(:));
end
% MorletFourierFactor = 4*pi/(6+sqrt(2+6^2));
% freq = 1./(scales.*MorletFourierFactor);
if nargout == 0 
    cla
    SCImg = wscalogram('image',Coeffs,'scales',freq,'ydata',sig,'xdata',t);
%     SCImg = wscalogram('image',Coeffs,'scales',freq);
%     figure
%     imagesc(real(SCImg))
%     axis xy
end