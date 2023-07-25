function C = Keep_cells_in_carray(IN, idx)
% 
% Keep certain cells and eliminate the rest from a cell array
% INPUT  : an input cell array and a list of indices to keep.
% OUTPUT : The reduced cell array
%
%function C = Keep_cells(IN, idx)


% cowen Sat Apr 17 15:31:12 1999
counter = 1;
X = 1:length(IN);
% Save only the cells that are not in the index
odd_ones = setdiff(X, idx);
C = Remove_cells_in_carray(IN,odd_ones);
