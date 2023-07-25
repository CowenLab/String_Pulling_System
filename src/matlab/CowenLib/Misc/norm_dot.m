function O = norm_dot(A, B)
% Compute the dotproducts of each column(normalized) in A with each column in B (normalized).
% 
% INPUT: Matrix A and B where each column is a vector.
% OUTPUT: The normalized dot product. (-1 to 1)

% Normalize:
O = Normalize_matrix(A)' * Normalize_matrix(B);
