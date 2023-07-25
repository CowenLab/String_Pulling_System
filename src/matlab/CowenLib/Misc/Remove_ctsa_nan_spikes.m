function [ good_ctsa, bad_ctsa, sum_bad_ctsa] = ...
    Remove_ctsa_nan_spikes(A_tsa, P_tsd1, P_tsd2);
%
% Create a new tsa that only has spike timestamps that were associated
% with real positions in the P_tsd. A non-real position is defined to
% be an X or Y value of NaN.
%
% INPUT:  a ts array of cells to be reduced
%         a tsd that contains real values and Nans
%
% OUTPUT: a new ts array that only contains timestamps where real data was found.
%
%function [ good_ctsa, bad_ctsa, sum_bad_ctsa] = Remove_ctsa_nan_spikes(A_tsa, P_tsd);
%
%

% cowen Sat Apr 17 13:41:09 1999

S = [];

for cellid = 1:length(A_tsa)
  if(nargin == 2)
    [good_ctsa{cellid}, bad_ctsa{cellid}] = ...
	Remove_ts_nan_spikes(A_tsa{cellid}, P_tsd1);
  elseif(nargin == 3)
    [good_ctsa{cellid}, bad_ctsa{cellid}] = ...
	Remove_ts_nan_spikes(A_tsa{cellid}, P_tsd1, P_tsd2);
  end
  S = [S;Data(bad_ctsa{cellid})];
end
%size(S)
sum_bad_ctsa = ts(unique(S)');


