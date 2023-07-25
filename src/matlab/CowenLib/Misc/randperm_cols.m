function M = randperm_cols(M)
%function M = randperm_cols(M)
% Randomly permute the values in the columns of each row of M. This is
% useful for permutation significance testing in the paired sample condition 
% each row is an observation) as it explicitly tests the null hypothesis.
%
% INPUT: Matrix 
% OUTPUT: Matrix whith the columns in each row randomly scrambled.
%
% cowen
c = size(M,2);
for ii = 1:size(M,1)
    M(ii,:) = M(ii,randperm(c));
end