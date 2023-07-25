function h = hamming_half(n)
% A half hanning window - good for looking at prospective coding as it does
% not smear information from the past when you convolve.
% Cowen 2020
midpt = round(n/2);
h = hamming(n);
h(1:midpt) = 0;
