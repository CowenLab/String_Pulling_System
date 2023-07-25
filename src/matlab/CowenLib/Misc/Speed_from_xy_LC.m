function [spd, acc, txy] = Speed_from_xy_LC(M, filt_factor, pixels_per_cm)
% INPUT: A matrx col1 = time, col 2 = x, col 3 = y
% OR If only 2 cols, the second col is predicted to be a measure of speed
% in only one dimension.
%
% If you want output in cm/sec be sure that the first col of M is in
% SECONDS. You should also convert your xy data to cm or pass in the pixels
% per cm input.
%
% OUTPUT: Speed - after some smoothing in units/whatever units the first
% col of M is.
%
% cowen
if nargin < 2 || isempty(filt_factor)
    filt_factor = 19;
end
if nargin < 3
    pixels_per_cm = 1;
end
% Get rid of the zeros.
M(sum(M(:,2:end),2) ==0 ,2:end) = nan;
d = diff(M(:,2));
% goodix = find(abs(d)<15);
BIX = isnan(M(1:(end-1),2)) | abs(d) >=15;
x = interp1(M(~BIX,1),M(~BIX,2), M(:,1),'spline');
x = sgolayfilt(x,3,filt_factor);
dx = [0;diff(x)];
t = M(:,1);
dt = [0;diff(t)];
if Cols(M) == 3
    % Get rid of the zeros.
    %M(M(:,3) ==0 ,3) = nan;
    d = diff(M(:,3));
    % ARBITRARY!!!
    BIX = isnan(M(1:(end-1),3)) | abs(d) >=15;
    y = interp1(M(~BIX,1),M(~BIX,3), M(:,1),'spline');
    y(y<1) = nan;
    % Yes, we do need to smooth this.
    % SMOOTH
    y = sgolayfilt(y,3,filt_factor);
    % Get the change in position.
    dy = [0;diff(y)];
    % determine the speed
    dist = sqrt(dx.^2 + dy.^2);
elseif Cols(M) == 2
    dist = [0;sqrt(diff(x).^2)];
end
% convert dist to cm
dist = dist/pixels_per_cm;

vel = dist./dt; % DO NOT DIVIDE BY ASSUMPTION OF 10000 samples per second.
% NOTE: vel is not really showing heading. It's always positive.
spd = abs(vel);
spd = sgolayfilt(spd,3,filt_factor);
spd(spd < 0) = 0; % Smoothing can make things dip to negative speed which makes no sense.
acc = [nan; diff(spd)];
if nargout > 2
    txy = [t x y];
end

if nargout == 0
    plot(t,x,t,y,t,spd)
    legend
end
