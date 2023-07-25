function o = slidingstd_fastest(x,w)
%function o = slidingstd_fastest(x,w)
% This is from the mathworks. I tried a couple of versions and this really
% is orders faster than most and simple.
% cowen 2014
%w = 3;                      % sliding window size
%x = [4 8 1 1 1 7 9 3];      % input signal
x = x(:)';
IX = isnan(x);
x(IX) = nanmean(x);

N = length(x);              % length of the signal

% element count in each window
n = conv(ones(1, N), ones(1, w), 'same');

% calculate s vector
s = conv(x, ones(1, w), 'same');

% calculate q vector
x = x .^ 2;
x = conv(x, ones(1, w), 'same');

% calculate output values
o = (x - s .^ 2 ./ n) ./ (n - 1);

% have to take the square root since output o is the 
% square of the standard deviation currently
o = o .^ 0.5;
o(IX) = nan;