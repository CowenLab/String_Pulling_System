function idx = Find_string_in_ca(ca,a_string,option)
% function idx = Find_string_in_ca(ca,a_string)
% Search through a cell array for a string
% if the string is really a cell array of strings, then
%  iteratively go through each one and return each index
if nargin == 2
    option = 'exact';
end
if iscell(a_string)
    for ii = 1:length(a_string)
        idx{ii} = Find_string_in_ca(ca,a_string{ii});
    end
else
    idx = [];
    switch option
        case 'exact'
            for ii = 1:length(ca)
                if strcmp(ca{ii},a_string)
                    idx(end+1) = ii;
                end
            end
        case 'contains'
            for ii = 1:length(ca)
                if findstr(ca{ii},a_string)
                    idx(end+1) = ii;
                end
            end
        otherwise
            error('incorrect option');
    end
end