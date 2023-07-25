function [a,b] = Notch_filter( fs, f_notch, notchWidth)
% To apply the filter, just do this...
% L = filtfilt(b,a,DATA);
% [a,b] = INTAN_notch_filter( fs, f_notch, notchWidth)
error('word on the street is that this does not work as well as notch_filter_cowen')
fn = fs/2;              %Nyquist frequency
freqRatio = f_notch/fn;      %ratio of notch freq. to Nyquist freq.
if nargin < 3
    notchWidth = 0.1;       %width of the notch. For most cases, use .1, but to notch out say 5 hz, I like a lower width of .01.
    %     notchWidth = 0.001;       %width of the notch. For most cases, use .1, but to notch out say 5 hz, I like a lower width of .01.
end
%Compute zeros
notchZeros = [exp( sqrt(-1)*pi*freqRatio ), exp( -sqrt(-1)*pi*freqRatio )];
%Compute poles
notchPoles = (1-notchWidth) * zeros;
% 
% figure;
% zplane(zeros.', poles.');
b = poly( notchZeros ); % Get moving average filter coefficients
a = poly( notchPoles ); % Get autoregressive filter coefficients
 figure;
 freqz(b,a,fs,fs)
%filter signal x
% y = filter(b,a,x);


% d = designfilt('bandstopiir','FilterOrder',2, ...
%                'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
%                'DesignMethod','butter','SampleRate',Fs);


% wo = fNotch/(sFreq/2);  bw = wo/35;
% [b,a] = iirnotch(wo,bw); %requires a special toolbox. 
% fvtool(b,a);
%Set up filter
% tstep = 1/sFreq;
% Fc = fNotch*tstep;
% dn = exp(-2*pi*(Bandwidth/2)*tstep);
% b = (1 + dn*dn)*cos(2*pi*Fc);
% a0 = 1;
% a1 = -b;
% a2 = dn*dn;
% a = (1 + dn*dn)/2;
% b0 = 1;
% b1 = -2*cos(2*pi*Fc);
% b2 = 1;


% 
% fs = 20000;             %#sampling rate
% f0 = 50;                %#notch frequency
% fn = fs/2;              %#Nyquist frequency
% freqRatio = f0/fn;      %#ratio of notch freq. to Nyquist freq.
% 
% notchWidth = 0.1;       %#width of the notch
% 
% #%Compute zeros
% notchZeros = [exp( sqrt(-1)*pi*freqRatio ), exp( -sqrt(-1)*pi*freqRatio )];
% 
% %#Compute poles
% notchPoles = (1-notchWidth) * notchZeros;
% 
% figure;
% zplane(notchZeros.', notchPoles.');
% 
% b = poly( notchZeros ); %# Get moving average filter coefficients
% a = poly( notchPoles ); %# Get autoregressive filter coefficients
% 
% figure;
% freqz(b,a,32000,fs)
% 
% %#filter signal x
% y = filter(b,a,x);