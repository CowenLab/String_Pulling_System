function norm_M = Z_scores(M,mn,sd)
%
% Change a passed in matrix to Z scores. The means are computed for
% each column and each item in a column has the mean subtracted from
% it and the results are divided by the std. 
%
% INPUT: Matrix or vector to normalize
% optional: Pass in your own means and stds. must be vector of equal points as the rows in M.
%
% OUTPUT: Z scores(same size as input matrix)
%
%function norm_M = Z_scores(M)
%


% cowen Wed Apr 28 11:46:40 1999

[rows, cols] = size(M);
if nargin == 1
    means = nanmean(M);
    stds = nanstd(M);
else
    means = mn(:)';
    stds = sd(:)';
end
stds(find(stds==0)) = inf; %get rid of the divide by zero.
Means = repmat(means,rows,1);
Stds = repmat(stds, rows,1);
norm_M = (M-Means)./Stds;
