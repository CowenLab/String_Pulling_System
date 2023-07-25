function O = simpleSTC_plot(binsize,STA,STC,RawMu,RawCov)
% NOTE - simpleSTC alignes everyting so that only data at and BEFORE the
% spike time are shown: NOTHING after the spike is analyzed. If you want
% this, add something to the spike times.
% Cowen.
x = linspace(binsize/2,Rows(STA)*binsize - binsize/2,Rows(STA));
if nargin > 2
    nw = 2;
else
    nw = 1;
end

figure
subplot(nw,2,1)
plot(x,STA); title('STA')
subplot(nw,2,2)
imagesc(x,x,STC)
if nargin > 2
    subplot(nw,2,3)
    plot(x,RawMu); title('Raw')
    subplot(nw,2,4)
    imagesc(x,x,RawCov)
end