function R = overlap_AB(A,B)
%
%   R = overlap_AB(A,B)
%
%  R = overlap of pairwise column vectors of 2 rectangular matrices with SAME NUMBER OF ROWS (= samples).
%  If  A = nR x nC1   and B = nR x nC2  R will be nC1 x nC2 matrix of overlap coefficents in the range [0..1]
%  R_ij of each pair of columns A(:,i)  and B(:,j).
%
% PL 04/23/01
% 

[nRa, nCa] = size(A);
[nRb, nCb] = size(B);
if nRa ~= nRb
    error(' Matrices A and B must have same number of ROWS (samples)!' );
end

nrmdA = A./repmat(sqrt(sum(A.*A)),nRa,1); 
nrmdB = B./repmat(sqrt(sum(B.*B)),nRb,1);

R = (nrmdA' * nrmdB);
