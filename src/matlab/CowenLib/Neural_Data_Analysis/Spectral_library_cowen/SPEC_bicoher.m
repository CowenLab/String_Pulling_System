function [bic,x] = SPEC_bicoher(data,sfreq,nfft, wind, nsamp, overlap))
% presumes that you have the Higher-Order Spectral Analysis Toolbox by
% Swami installed. You need to convert the files in this toolbox to
% lowercase.
% Cowen 2019 
bicoher(data,nfft,wind,nsamp,overlap);
% I really don't konw if this is how this is working.
axis equal
axis square
set(gca,'XTickLabel',get(gca,'XTick')*sfreq/2+sfreq/4)
set(gca,'YTickLabel',get(gca,'YTick')*sfreq/2+sfreq/4)
a = axis;
hold on
plot(a([1 2])',a([3,4])')
plot(a([1 2])',a([2,1])')
