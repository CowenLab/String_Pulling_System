function [t,st] = Find_end(ctsa_array)
% Find the minimum or maximum end time in an array of ts or tsd or ctsd objects
% 
% INPUT: array of ts, tsd, or ctsds, or a vector of timestamps
%        find_min = specifies whether to take the minimum end time
%        in the array or the maximum end time. Default is false(0)
%        so pass in a non zero number if you want the minimum end
%        time returned.
%
% OUTPUT: an end time.

% cowen Fri Jul  2 16:21:36 1999
% Cowen - simplifed. NOTE: will need to convert ts objects to numbers if
% this ever becomes an issue.

ncells = length(ctsa_array);

st = nan(ncells,1);
for cellid = 1:ncells
    if ~isempty(ctsa_array{cellid})
        st(cellid) = max(ctsa_array{cellid});
    end
end
t = nanmax(st);
