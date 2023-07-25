function D = Sem3d(A)
% INPUT: a 3d matrix A
% OUTPUT: a 2d matrix of the first two dimesions of A. The mean is 
%         generated across the third dimension.
%

% cowen

[i j k] = size(A)
B = reshape(A,i*j,k)
C = Sem(B,2)
D = reshape(C,i,j)
