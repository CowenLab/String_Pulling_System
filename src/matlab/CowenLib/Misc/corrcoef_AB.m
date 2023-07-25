function R = corrcoef_AB(A,B)
%
%   R = corrcoef_AB(A,B)
%
%  R = correlation coefficent of 2 rectangular matrices with SAME NUMBER OF ROWS (= samples).
%  If  A = nR x nC1   and B = nR x nC2  R will be nC1 x nC2 matrix of corrlation coefficents
%  R_ij of each pair of columns A(:,i)  and B(:,j).
%
% This function is a generalization of the matlab function corrcoef(A) which corresponds to corrcoef_AB(A,A)
%
% PL 04/23/01
% 

[nRa, nCa] = size(A);
[nRb, nCb] = size(B);
if nRa ~= nRb
    error(' Matrices A and B must have same number of ROWS (samples)!' );
end

stdA = (A-repmat(mean(A),nRa,1))./(repmat(std(A),nRa,1));
stdB = (B-repmat(mean(B),nRb,1))./(repmat(std(B),nRb,1));

R = (stdA' * stdB)/(nRa-1);
