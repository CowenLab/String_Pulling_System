function demo_smoothing_and_convolution()
% Illustrate the basics of convolution and smoothing.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2022
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Convolution.
sig = zeros(1,100);
sig(20) = 1;
ker = hanning(11);
half_ker = ker;
half_ker(1:5) = 0;
figure
plot(ker);hold on; plot(half_ker)

figure
plot(sig,'k')
hold on
plot(conv(sig,ker,'same'),'b')
plot(conv(sig,half_ker,'same'),'r')
legend('orig','han','half_han')
% Ask yourself: if you wanted to ensure the data you are analyzing is not
% falsely interpreted as being 'causal' to some change in measure (e.g.,
% dopamine release following single-unit activity), which of the two
% kernels would you use? 

% now make a slightly more complex signal...
sig = double(rand(1,100)>.9);
figure
plot(sig,'k')
hold on
plot(conv(sig,ker,'same'),'b')
plot(conv(sig,half_ker,'same'),'r')
legend('orig','han','half_han')

% Anoter nice way to smooth... Mabe not perfect for discrete data though as
% you get edge effects and negative numbers.
figure
plot(sig,'k')
hold on
plot(sgolayfilt(sig,3,11),'b')
legend('orig','sgolay poly filt')

% Other nice ways to smooth... 
% Note how mov median - does its job but will return zeros for sparse data.
% Great for outlier reduction, not great for sparse spike trains.
figure
plot(sig,'k')
hold on
plot(movmean(sig,11),'b')
plot(movmedian(sig,11),'r')
legend('orig','mov mean','mov median')

% Exercise for the student: Do above, but create a continuous signal
% instead of the discrete spike-like signal that I used and investigate the
% results.