function O = isempty_in_cell_array(ca)
% Find the elements in a cell array that are empty.
O = zeros(size(ca));
for ii = 1:length(ca)
    if isempty(ca{ii})
        O(ii) = 1;
    end
end