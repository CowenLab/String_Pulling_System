function ix = cell_find(base_str,target_str)
% Finds a match of target_str in the cell array base_str
ix = [];
for ii = 1:length(base_str)
    if strcmp(base_str{ii},target_str)
        ix = [ix ii];
    end
end