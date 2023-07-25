function [Y sd] = pdist_for_bootstrap(X,X2,dist,varargin)
% stupid matlab bootstrp wigs out when you pass a string array as a
% function argument. It attempts to boostrap the string array.
% INPUT
%function Y = pdist(X,dist,varargin)
%PDIST Pairwise distance between observations.
%   Y = PDIST(X) returns a vector Y containing the Euclidean distances
%   between each pair of observations in the N-by-P data matrix X.  Rows of
%   X correspond to observations, columns correspond to variables.  Y is a
%   1-by-(N*(N-1)/2) row vector, corresponding to the N*(N-1)/2 pairs of
%   observations in X.
%
%   Y = PDIST(X, DISTANCE) computes Y using DISTANCE.  Choices are:
%
%       'euclidean'   - Euclidean distance
%       'seuclidean'  - Standardized Euclidean distance, each coordinate
%                       in the sum of squares is inverse weighted by the
%                       sample variance of that coordinate
%       'cityblock'   - City Block distance
%       'mahalanobis' - Mahalanobis distance
%       'minkowski'   - Minkowski distance with exponent 2
%       'cosine'      - One minus the cosine of the included angle
%                       between observations (treated as vectors)
%       'correlation' - One minus the sample linear correlation between
%                       observations (treated as sequences of values).
%       'spearman'    - One minus the sample Spearman's rank correlation
%                       between observations (treated as sequences of values).
%       'hamming'     - Hamming distance, percentage of coordinates
%                       that differ
%       'jaccard'     - One minus the Jaccard coefficient, the
%                       percentage of nonzero coordinates that differ
%       'chebychev'   - Chebychev distance (maximum coordinate difference)
%       12 - mean percentage change.
a = {'euclidean' 'seuclidean' 'cityblock' 'mahalanobis' 'minkowski'  'cosine' 'correlation' 'spearman' 'hamming'   'jaccard'  'chebychev'};
if dist <= 11
    Y = pdist([X(:) X2(:)]',a{dist},varargin);
else
    switch dist
        case 12 % Mean Percentage Change
            Y = nanmean([X2(:) - X(:)]./[X2(:) + X(:)]);            
            sd = nanstd([X2(:) - X(:)]./[X2(:) + X(:)]);
    end
end