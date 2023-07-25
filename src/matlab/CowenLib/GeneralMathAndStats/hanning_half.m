function h = hanning_half(n)
% A half hanning window - good for looking at prospective coding as it does
% not smear information from the past when you convolve.
% Cowen 2010
midpt = round(n/2);
h = hanning(n);
h(1:midpt) = 0;
