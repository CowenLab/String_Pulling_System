function [a,b] = INTAN_notch_filter( fs, f_notch, notchWidth)
fn = fs/2;              %Nyquist frequency
freqRatio = f_notch/fn;      %ratio of notch freq. to Nyquist freq.
if nargin < 3
    notchWidth = 0.1;       %width of the notch. For most cases, use .1, but to notch out say 5 hz, I like a lower width of .01.
    %     notchWidth = 0.001;       %width of the notch. For most cases, use .1, but to notch out say 5 hz, I like a lower width of .01.
end
%Compute zeros
zeros = [exp( sqrt(-1)*pi*freqRatio ), exp( -sqrt(-1)*pi*freqRatio )];
%Compute poles
poles = (1-notchWidth) * zeros;
% 
% figure;
% zplane(zeros.', poles.');
b = poly( zeros ); % Get moving average filter coefficients
a = poly( poles ); % Get autoregressive filter coefficients
% figure;
% freqz(b,a,fs,fs)
%filter signal x
% y = filter(b,a,x);