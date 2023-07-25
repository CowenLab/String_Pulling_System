% Tests the accuracy of Align_spike_times.
try
    load('Align_spike_times_test_data.mat','d')
catch
    d = abs(randn(1,1000)*100);
    %save('Align_spike_times_test_data.mat','d')
    disp('Using random data')
end
%
t        = cumsum(d);
t        = t - mean(t);
evts     = linspace(min(t),max(t),40);
interval = mean(diff(evts));
dt_msec  =20;
time_before_msec = 1000;
time_after_msec  = 1000;
figure
tic
Align_spike_times(t,evts,dt_msec,time_before_msec,time_after_msec,3);
toc
figure
t2 = sort([t evts]);
tic
Align_spike_times(t2,evts,dt_msec,time_before_msec,time_after_msec,3);
toc
title(['event interval should be ' num2str(interval/10) 'msec' ])

figure
t2 = sort([t evts]);
tic
Align_spike_times(t2,evts,[dt_msec/4 dt_msec],time_before_msec,time_after_msec,3);
toc
title(['sliding window interval should be ' num2str(interval/10) 'msec' ])