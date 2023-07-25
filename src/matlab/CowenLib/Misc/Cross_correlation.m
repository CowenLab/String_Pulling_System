function [corr,lags] = Cross_correlation(ts_1 , ts_2, maxshift, binsize_msec)
% Does a cross correlation on two ts objects. Default is 1 second and 10 ms bin size
% [acorr,lags] = Cross_correlation(ts_1 , ts_2, maxshift, binsize)


if nargin == 2
  maxshift = 10000;
  binsize_msec = 10;
elseif nargin == 3
  binsize_msec = 10;
end

lags = -maxshift:binsize_msec*10:maxshift;

Q1 = Data(MakeQfromS({ts_1}, binsize_msec*10));
Q2 = Data(MakeQfromS({ts_2}, binsize_msec*10));

if length(Q1)<=1 | length(Q2)<=1
  disp('One of the inputs does not have more than one point.')
  acorr = 0;
  return
end


maxlag = maxshift/binsize_msec;

corr = xcorr(full(Q1), full(Q2), maxlag);


if nargout == 0
  if isequal(Q1,Q2)
    corr(floor(length(corr)/2+1)) = 0;    % set 0 lag to 0 for scaling
  end
  bar(lags/10000, corr);			% show acorr
  H = findobj(gca, 'Type', 'patch');
  set(H, 'facecolor', [0 0 0])
  set(gca, 'YLim', [0 1.1*max(corr)]);
  title('crosscorrelation')
  xlabel('Seconds');
end