function [PC, SCORE, variances, TSQUARE] = Prin_comp(M)
% The princomp barfs if you have more examples than variables so I fudge by doubling
% the size of the M matrix.

% cowen
r =  size(M,1);
c =  size(M,2);

if r < c
  [PC, SCORE, variances, TSQUARE] = princomp([M;M]);
  SCORE(r+1:end,:) = [];
  TSQUARE(r+1:end) = [];
  
  disp('WARNING: More variables than observations')
  
else
  [PC, SCORE, variances, TSQUARE] = princomp(M);
end
