function M = randperm_rows(M)
%function M = randperm_cols(M)
% Randomly permute the values in the rows of M. This is
% useful for permutation significance testing in the paired sample condition 
% each row is an observation) as it explicitly tests the null hypothesis.
%
% INPUT: Matrix 
% OUTPUT: Matrix whith the rows randomly permuted (same size as M)
%
% cowen
r = randperm(size(M,1));
M = M(r,:);
