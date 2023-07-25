function [u_string, idx] = unique_string(strings)
%function [u_string, idx] = unique_string(strings)
% find the unique elements contained in a matrix of string where 
% each row is a new string.
% INPUT: a matrix of strings
% OUTPUT: a matrix of the unique strings. output is sorted.
%         indices of the original matrix where those strings were found

% cowen

% sort everything
[strings, sort_idx]   = sortrows(strings);

% The first elemnent is unique by definition.
u_string  = strings(1,:);
idx       = sort_idx(1);

for ii = 2:Rows(strings) - 1
    if strcmp(u_string(end,:),strings(ii,:) )
        % not unique
    else
        % unique
        u_string = [ u_string; strings(ii,:)];
        idx      = [ idx; sort_idx(ii)];
    end
    
end
