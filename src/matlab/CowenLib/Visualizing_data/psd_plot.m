function out = psd_plot(Data, nfft, sFreq, window, noverlap)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% out = psd_plot(Data, nfft,sFreq,window,noverlap)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT: 
%
% OUTPUT:
%
% Note: You need to have the window size and nfft equal to the 
%  sFreq if you want to view at a resolution of 1HZ.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[F, Fconf, xF] = psd(Data, nfft, sFreq, window, noverlap);
plot(xF,F); 
hold on;
plot(xF,Fconf(:,1),'r:'); 
plot(xF,Fconf(:,2),'r:'); 
axis tight;
xlabel('Freq')
ylabel('dB')
title('psd')
