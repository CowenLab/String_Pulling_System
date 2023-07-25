function [O,A] = Norm_mult(S, M)
%
% Normalize and then multiply each column vector in matrix with every
% other column in another matrix. This avoids the memory issues of
% simply multiplying the two matrices together and taking the sub
% matrix. The matrices are normalizes(euclidean) in order to get an
% comparable dot product value. Note: you should normalize the rows in
% the matrices by the mean(ala z score) to avoid problems when on
% cell fires a lot versus others.
%
% INPUT:  S = Target matrix
%         M = the matrix to compute the dot product between each column to all columns in S
%
% OUTPUT: O = The matrix of dot products. Cols of S by rows of S and M.
%
%function [O,A] = Norm_mult(S, M)

% cowen Thu Apr 22 10:24:21 1999

[rM,cM] = size(M);
[rS,cS] = size(S);
if rM ~= rS
  error('matrices must have same number of rows')
end
S(find(isnan(S))) = 0; % Nans screw up the normalization.
M(find(isnan(M))) = 0;
norm_S = Normalize_matrix(S); %So each column vector has a length of 1
norm_M = Normalize_matrix(M); %So each column vector has a length of 1
O = norm_S'*norm_M;

