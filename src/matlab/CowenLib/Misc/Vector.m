function v = Vector(M)
% make a horizontal vector out of a matrix.
[rows cols] = size(M);
v = reshape(M, 1, rows * cols);
