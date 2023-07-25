function [O,A] = Compare_vectors(M, S)
%function [O,A] = Compare_vectors(M, S)
%
% Compare every vector in S to each of the vectors in the matrices
% contained in the cell array M. Compare_vectors will then categorize
% the vector as being closest to one of the cells in
% M. Compare_vectors then returns the count of matches to each of the
% vectors in each of the categories in M. The length of the vector O
% will be equal to the length of the cell array.
%
% INPUT:  M = cell array of matrices to compare to S
%         S = the matrix to compare to M
%
% OUTPUT: O = a vector of length(M) that contains the count of matches
%         to S.

% cowen Thu Apr 22 10:24:21 1999
if ~iscell(M)
  X = M;
  M = [];
  M{1} = X;
  clear X
end

elements = length(M);

% Find the similarity(normalized dot product) between vectors in each
% M(1:elements). Calculate the maximum match between sleep and maze
% for each bin of sleep. This

norm_S = Normalize_matrix(S);
%norm_factor = sqrt(sum(full(S).^2));
%norm_factor_matrix = repmat(norm_factor,Rows(S),1);
%norm_S = S./(norm_factor_matrix + eps);

disp('Normalizing and calculating mean dot product.');
for ii = 1:elements
  norm_M = Normalize_matrix(M{ii});
  %norm_factor  = sqrt(sum(M{ii}.^2));
  %norm_factor_matrix = repmat(norm_factor,Rows(M{ii}),1);
  %norm_M = M{ii}./(norm_factor_matrix + eps);
  mean_dot{ii} = mean(norm_M'*norm_S); % a measure of the mean similarity of 
  fprintf(' M %d',ii);                 % one vector to all the vectors in M.
end
fprintf('\n'); 


maximums = zeros(elements,Rows(mean_dot{1}));

for ii = 1:elements
  A(ii,:) = mean_dot{ii};
end
maximums = max(A);
size(maximums);
COMPARE = repmat(maximums,elements,1);
MATCHES = A==COMPARE;
O = sum(MATCHES');

smax = Cols(maximums);
smax = 100;
%error('a')