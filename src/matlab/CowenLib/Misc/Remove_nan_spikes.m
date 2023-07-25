function new_ts = Remove_nan_spikes(A_ts, P_tsd);
%
% Create a new ts that only has spike timestamps that were associated
% with real positions in the P_tsd. A non-real position is defined to
% be an X or Y value of NaN.
%
% INPUT:  a ts to be reduced
%         a tsd that contains real values and Nans
%
% OUTPUT: a new ts that only contains timestamps where real data was found.
%
%
%

% cowen Sat Apr 17 13:41:09 1999

TS = Data(A_ts);
Px = Data(P_tsd);
Tx = Range(P_tsd,'ts');

new_ts = [];

% Go through each spike ts and find the associated position. If it is
% a non-nan value, then save it.
for spk = 1:length(TS)
  idx = binsearch(Tx, TS(spk));
  if ~isnan(Px(idx)) 
    new_ts = [new_ts; TS(spk)];
  end
end
