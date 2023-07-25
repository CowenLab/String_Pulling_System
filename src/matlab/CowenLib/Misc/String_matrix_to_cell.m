function B = String_matrix_to_cell(A)
% Convert a string matrix to a cell array
% INPUT, a matrix where each row is a word.
%
%

for ii = 1:size(A,1)
    B{ii} = A(ii,:);
end
