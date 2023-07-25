%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter tutorial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
% Creating a filter using Yulewalk -- it will approximate a filter given
% a band up to the order you specify.
Fs = 1000; % sampling frequency
FiltOrder = 10;

Ripple = 1; % I don't understand this parameter (cheby1 filter parameter)
Nq = Fs/2; % 1/2 the sampling freq.
lower_cutoff_Hz = 30; % in fq
upper_cutoff_Hz = 50; % in fq
lower_cutoff_Nq = lower_cutoff_Hz/Nq % Convert to Niquist. All matlab routines require this. 
upper_cutoff_Nq = upper_cutoff_Hz/Nq
F = 0:.001:1;
M = zeros(size(F));
idx_low = find(F>=lower_cutoff_Nq);
idx_high = find(F>=upper_cutoff_Nq);
idx_low = idx_low(1);
idx_high = idx_high(1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% I want to have a square band pass around the low and high bands
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
M(idx_low:idx_high) = 1;
figure;
plot (F*Nq,M)
title('Desired function')
ylabel('Freq')
xlabel('Magnitude')
% Create the filter
[Yb,Ya] = yulewalk(FiltOrder, F,M); % This is best for MULTI-Band (more than one band) filters.
[Bb,Ba] = butter(FiltOrder, [lower_cutoff_Nq upper_cutoff_Nq]); % use 'stop' for bandstop.
[Cb,Ca] = cheby1(FiltOrder, Ripple,[lower_cutoff_Nq upper_cutoff_Nq]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show it's response propertiess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hold on
Yfr = freqz(Yb,Ya,256); % h = the frequency response. I really don't understand the 256 part.
Bfr = freqz(Bb,Ba,256); % h = the frequency response. I really don't understand the 256 part.
Cfr = freqz(Cb,Ca,256); % h = the frequency response. I really don't understand the 256 part.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Normalize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Yfr = abs(Yfr)/max(abs(Yfr));
Bfr = abs(Bfr)/max(abs(Bfr));
Cfr = abs(Cfr)/max(abs(Cfr));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For some reason, h is sinusoidal so you need to take the abs to get the tuning response.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hy = linspace(0,1,length(Yfr));
figure
plot (F*Nq,M,hy*Nq,Yfr,hy*Nq,Bfr,hy*Nq,Cfr)
legend('desired','yule','butter','cheby1')
xlabel('Frequency')
title(['Filter Order ' num2str(FiltOrder)])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% How to get a power spectra.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sF = 1000; %Hz
Nq = sF/2;
t = 0:1/sF:50; % time in seconds. 
y = sin(t*(10*2*pi)) + sin(t*(100*2*pi)) + randn(size(t)); % random data oscillating at 10Hz and 100Hz
figure;
subplot(3,1,1)
plot(t,y);
[F,x] = pburg(y,6,sF);
subplot(3,1,2)
plot(x,F); axis tight
subplot(3,1,3)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Critical! IF you want single Hz resolution, then your window size needs to be equal to the
% sampling rate whcih also means that the order has to be equal to the sampling rate.
% It looks ugly with the fake data, but trust me on the real data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[F,Fconf,xF] = psd(x,sF,sF,sF);
plot(xF,F); 
hold on;
plot(xF,Fconf(:,1),'r:'); 
plot(xF,Fconf(:,2),'r:'); 
axis tight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% How to get spectragram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure
specgram(t,2^10,sF)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% How to run a coherence analysis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
