% test the bin_tim_by_intervals.c program.
%% Create some random spikes...
intervals_usec = rand(12000,1)*20000; % 50msec ISI on average for 20hz
intervals_usec(intervals_usec < 2000) = [];
t = cumsum(intervals_usec);
t = round(t);
hist(diff(t),100)

% bin them by some interval...

interval_for_binning = linspace(t(1),t(end),1000);

nspikes = length(t);
tic
B = bin_times_by_intervals(t,interval_for_binning(1:end-1)-1,interval_for_binning(2:end)+1);
toc

tic
HC = histc(t,interval_for_binning);
toc

figure(2010)
plot(1:length(B),B,'b',1:length(HC),HC,'r')
title(sprintf('nspikes %d, bin_times_b = %d histc = %d',nspikes,sum(B),sum(HC)))

