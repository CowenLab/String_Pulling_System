function se = Sem(X,dim)
% se = Sem(X) find the standard error of the mean
%
% INPUT: A matrix where each row is a sample and each column is a variable.
% A vector may also be passed in.
%
% OUTPUT: standard error of the mean of a sample - estimate of the
% population SE for each column in the input matrix.
%
%

% cowen Tue Jul 20 16:00:34 1999
% cowen 8/20/01 Improved managemement for matrices (not columns) by only counting non-nan data.
%   the previous version used length to determine the sample size. This was dangerous as length only 
%   takes the larges of the two dimensions.
% cowen 10/9/16 - fixed - should divide by sqrt(n) not sqrt(n-1).
%

if nargin < 2
    dim = 1;
end

% [r,c] = size(X);
% if r == 1
%     X = X(:);
% end
% X = X + eps;
if any(isnan(X(:)))
    non_nans_per_col = sum(~isnan(X),dim);  % number of non nan numbers in each column. Nan's are not counted
                                        % when considering sample size.
                                        
    se = nanstd(X,[],dim)./real(sqrt(non_nans_per_col)+eps);
else
    n = size(X,dim);
    se = std(X,[],dim)./sqrt( n );
end

if isempty(X)
    se = nan(1,Cols(X));
end
