function [good_ts, bad_ts] = Remove_ts_nan_spikes(A_ts, P_tsd1, P_tsd2);
%
% Create a new ts that only has spike timestamps that were associated
% with real positions in the P_tsd. A non-real position is defined to
% be an X or Y value of NaN.
%
% INPUT:  a ts to be reduced
%         a tsd that contains real values and Nans
%         you may enter two tsds, but this is optional
%
% OUTPUT: good_ts = a ts with the associated NAN spikes removed
%         bad_ts  = a ts that has teh ts where the NANs occurred
%
%function [good_ts, bad_ts] = Remove_ts_nan_spikes(A_ts, P_tsd1, P_tsd2);
%

% cowen Sat Apr 17 13:41:09 1999
% added another tsd Tue Apr 20 16:49:55 1999

TS = Data(A_ts);
if nargin == 3
  % Remember, all we want are Nans for x y pairs that you want
  % excluded. Adding a nan to a non nan will turn it into a nan and
  % thus eliminate it from analysis.
  Px = Data(P_tsd1) + Data(P_tsd2);
else
  Px = Data(P_tsd1);
end
Tx = Range(P_tsd1,'ts');

% Go through each spike ts and find the associated position. If it is
% a non-nan value, then save it.
GOOD = zeros(1,length(TS));
BAD = GOOD;
for spk = 1:length(TS)
  idx = binsearch(Tx, TS(spk));
  if ~isnan(Px(idx)) 
    GOOD(spk) = TS(spk);
  else
    BAD(spk) = TS(spk);
  end
end
GOOD(find(GOOD == 0)) = [];
BAD(find(BAD == 0)) = [];

good_ts = ts(GOOD');
bad_ts = ts(BAD');
