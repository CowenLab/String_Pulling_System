function C = Remove_cells_in_carray(IN, idx)
% 
% Remove unwanted cell members in a cell array.
% INPUT  : an input cell array and a list of indices to remove.
% OUTPUT : The reduced cell array
%
%function C = Remove_cells(IN, idx)


% cowen Sat Apr 17 15:31:12 1999
counter = 1;
X = 1:length(IN);
% Save only the cells that are not in the index
to_sort = setdiff(X, idx);

for ii = to_sort
  C{counter} = IN{ii};
  counter = counter + 1;
end
