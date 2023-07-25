function norm_M = Z_scores(M, opt_indices)
%
% Change a passed in matrix to Z scores. The means are computed for
% each column and each item in a column has the mean subtracted from
% it and the results are divided by the std. 
%
% INPUT: Matrix or vector to normalize
%        opt_indices - optional indicds (rows) in M that indicate which
%        part of the M matrix will be used to calculate the mn and sd.
%
% OUTPUT: Z scores(same size as input matrix)
%
%function norm_M = Z_scores(M)
%


% cowen Wed Apr 28 11:46:40 1999
if isempty(M)
    norm_M = [];
    return
end

[rows, cols] = size(M);
if nargin == 1
    means = nanmean(M);
    stds = nanstd(M);
else
    means = nanmean(M(opt_indices,:));
    stds = nanstd(M(opt_indices,:));
end
stds(find(stds==0)) = inf; %get rid of the divide by zero.
Means = repmat(means,rows,1);
Stds = repmat(stds, rows,1);
norm_M = (M-Means)./(Stds+eps);

