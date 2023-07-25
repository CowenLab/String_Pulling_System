function M = rotate_angular_linear_matrix(M, shift_per_row)
%function rotate_angular_linear_matrix(M, shift_per_row)
% Rotate a matrix, but only by shifting each successive column by 
% shift_per_row.
% 
% INPUT: M - the matrix to shift
%        shift_per_row - the amount to shift each row. The shift of each
%        row is equal to row_number*shift_per_row.
% 
nR = size(M,1);
for iR=1:nR
    M(iR,:) = circshift(M(iR,:)',round(iR*shift_per_row))';
end
