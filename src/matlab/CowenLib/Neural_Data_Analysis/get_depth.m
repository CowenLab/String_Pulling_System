function d = get_depth(ID,ID_ca,depths)
% function d = get_depth(ID,ID_ca,depths)
% Returns the depth for a given cell id (e.g. 'A4'). 
% The user must pass in a cell array of IDs and a vector of depth
% corresponding to each ID.
for ii = 1:length(ID_ca)
    if strcmp(deblank(upper(ID_ca{ii})), deblank(upper(ID)))
        d = depths(ii);
        return
    end
end
