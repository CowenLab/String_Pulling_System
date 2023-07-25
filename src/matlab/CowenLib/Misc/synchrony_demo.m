function synchrony_demo()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The False Sense Of Synchrony Demo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function illustrates how a linear combination of 
% desynchronized oscillations of the same frequency, when combined,
% appear as if they are oscillating in synchrony.
%
% For me this is counter-intuitive as you would thing that randmom
% shifts in phase would cancel out once averaged across many trials or 
% channels. This is not the case. A common fq band, even if out of phase,
% will show 'synchrony' in the _averaged_ cross-correlation and in the average
% PETH. For me, this casts considerable doubt on using any PETH or xcorr technique
% for measuring syncrony.
%
% The first figure of this demo also demonstrates the 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time_range_sec = [0 .5];
total_sec = diff(time_range_sec);
fq = 40;
sFreq1 = 200;
x_axis_sec = linspace(time_range_sec(1),time_range_sec(2),sFreq1*total_sec);
wv = sin(x_axis_sec/total_sec*2*pi*(fq*total_sec));
% 
figure
plot(x_axis_sec,wv)
hold on
title('The illusory low frequency component caused by having too low sampling fq (still well above Nq)')
% Resampling at a higher fq.
sFreq2 = 800;
x_axis_sec = linspace(time_range_sec(1),time_range_sec(2),sFreq2*total_sec);
wv = sin(x_axis_sec/total_sec*2*pi*(fq*total_sec));
plot(x_axis_sec,wv,'r:')
legend([num2str(sFreq1) 'Hz'],[num2str(sFreq2) 'Hz'])
nsamples = 1000;

M = zeros(nsamples,length(wv))*nan;
cumx = [];
for ii = 1:nsamples
    % Start M with a random phase shift between 0 and 2pi.
    M(ii,:) = sin(x_axis_sec/total_sec*2*pi*(fq*total_sec)+rand(1,1)*2*pi);
    %plot(M(ii,:))
    %hold on
    
    %pause
end
% A
figure
subplot(2,1,1)
title('The result of adding 1000 such waves with random phases')
imagesc(M)
subplot(2,1,2)
plot(nanmean(M))
axis tight
title('mean')

tmp = xcorr(M(1,:),M(2,:));
cumx = zeros(2000,length(tmp))*nan;
cnt = 1;
for ii = 1:nsamples
    for jj = ii+1:nsamples
        cumx(cnt,:) = xcorr(M(ii,:),M(jj,:));
        cnt = cnt + 1;
    end
    if cnt > 1000 
        break
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure;
subplot(2,1,1)
plot(nanmean(cumx))
title('XCORR: Even though everything is phase shifted, you still see oscillatory activity')
subplot(2,1,2)
plot(xcorr(M(1,:),M(2,:)),'r')
title('Data from a single perfect sign wave.')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
