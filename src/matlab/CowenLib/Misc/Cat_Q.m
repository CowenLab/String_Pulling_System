function O = Cat_Q(Q_ctsd, tsmatrix)
%
% Return a Qctsd that is restricted to just the intervals in the tsmatrix
%
% INPUT: Qctsd and a nx2 matrix of start, end timestamps.
%
% OUTPUT: The restricted Q matrix-- no longer a Qctsd unfortunately.

[r,c] = size(tsmatrix);

% Grab the first interval
O = Restrict(Q_ctsd, tsmatrix(1,1), tsmatrix(1,2) );

% if there is only one time interval, return, if not, process each element.
if r == 1
  return
end

% Go through each interval and catenate them together.
for ii = 2:r
  Restrict_Q_tsd = Restrict(Q_ctsd, tsmatrix(ii,1), tsmatrix(ii,2) );
  O = cat(O, Restrict_Q_tsd);
end
