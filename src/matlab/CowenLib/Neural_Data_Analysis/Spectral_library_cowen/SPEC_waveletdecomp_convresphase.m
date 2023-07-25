function [convresphase_out] = SPEC_waveletdecomp_convresphase(f,S,srate,width)
% function [convresphase_out] = SPEC_waveletdecomp_convresphase(f,S,srate,width)
%   returns phase, power (scaled to amplitude of input), and
%   the original signal filtered at each frequency
%   f = frequencies to analyze
%   S = signal
%   srate = sampling rate (hz)
%   width = wavelet width
% f = logspace(low,hi,100)
if f(1) == 0
    disp('Frequency is zero - not possible. Converting to .5 Hz.')
    f(1) = 0.5;
end
if size(S,1)>1
    S = S';
end
if any(isnan(S))
    disp('WARNING: NANS in DATA')
    IX = isnan(sum(S,2));
    [~,G] = find_intervals(IX,.5);
    G(:,1) = G(:,1) + 1; % to correct for an ideosyncracy in find_intervals
    G(:,2) = G(:,2) - 1;
end

convresphase_out = NaN(length(f),length(S),class(S));

wavetime=-3:(1/srate):3;% 2 seems arbitrary. Seems like we should use a value dependent on teh question.

for i = 1:length(f)
    wavef=f(i); % wavelet frequency
    % create wavelet
    w = 2*( width/(2*pi*wavef) )^2;
    mwave =  exp(1i*2*pi*wavef.*wavetime) .* exp( (-wavetime.^2)/w );
    % convolution variables
    halfwavsize = floor(length(wavetime)/2);
    Lconv = length(mwave) + length(S) -1;
    
    mwavefft = fft(mwave,Lconv);
    % run convolution
    Sfft=fft(S,Lconv);
    convresphase = ifft(mwavefft .* Sfft ,Lconv);
    convresphase = convresphase(halfwavsize:end-halfwavsize-1);
    convresphase_out(i,1:length(convresphase)) = convresphase;
end


