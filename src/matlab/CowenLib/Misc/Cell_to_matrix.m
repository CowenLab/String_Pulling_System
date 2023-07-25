function M = Cell_to_matrix(CA)
% Convert a cell array to a matrix. This only works if the dimensions of each
% element in the cell array are all equal
%
% INPUT: cell array
%
% OUTPUT: matrix of length(CA), by the number of elements in each array
%
% M = Cell_to_matrix(CA)

% cowen Mon Apr 26 11:21:49 1999
% modified to allow cells to be matrices and not just vecrtors

reshape_C = 0;
 
[rows,cols] = size(CA{1});

if length(CA) == 0
  error('the array is empty');
end

if rows ~=1 | cols ~=1
  %disp('Array elements are matrices. Reshaping the matrices to vectors.')
  reshape_C = 1;
end
  
M = zeros(length(CA),rows*cols);

for ii = 1:length(CA)
  [new_r, new_c] = size(CA{ii});
  if new_r ~= rows | new_c ~= cols
    error('Elements in the cell array are of different dimensions');
  end
  
  if reshape_C
    M(ii,:) = reshape(CA{ii},1,rows * cols);
  else
    M(ii,:) = CA{ii};
  end
end
