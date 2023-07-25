function [phase,pow,filtsig,kernals] = waveletdecomp(f,S,srate,width)
%[phase,pow,filtsig] = waveletdecomp(f,S,srate,width)
%   returns phase, power (scaled to amplitude of input), and
%   the original signal filtered at each frequency
%   f = frequencies to analyze
%   S = signal
%   srate = sampling rate (hz)
%   width = wavelet width

if size(S,1)>1
    S = S';
end
S = single(S);
%preallocate
pow = zeros(numel(f),numel(S),'single');
phase = zeros(numel(f),numel(S),'single');
filtsig = zeros(numel(f),numel(S),'single');
%time for wavelet
wavetime = single(-20:(1/srate):20);
Lconv = length(wavetime) + length(S) -1;
Lconv2 = pow2(nextpow2(Lconv));
%preallocate kernal storage
kernals = zeros(numel(f),numel(wavetime));
%signal fft
Sfft=fft(S,Lconv2,2);
for i = 1:numel(f)
    wavef=f(i); % wavelet frequency
    % create wavelet
    w = 2*( width/(2*pi*wavef) )^2;
    mwave =  exp(1i*2*pi*wavef.*wavetime) .* exp( (-wavetime.^2)/w );
    kernals(i,:) = mwave;
    %wavelet fft
    mwavefft = fft(mwave,Lconv2);
    %inverse wavelet fft
    convrespow = ifft((mwavefft./max(mwavefft)) .* Sfft ,Lconv2);
    convrespow = convrespow(1:Lconv);
    
    startIndex=ceil(length(wavetime)/2);
    endIndex=length(convrespow)-floor(length(wavetime)/2);
    
    convrespow = 2*convrespow(startIndex:endIndex);
   
    % create power and phase
    pow(i,:) = abs(convrespow).^2;
    phase(i,:)= atan2(imag(convrespow),real(convrespow));
    filtsig(i,:)= real(convrespow);
end
end

