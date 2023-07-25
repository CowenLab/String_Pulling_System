function [t,st] = Find_start(ctsa_array)
% Find the minimum or maximum start time in an array of ts or tsd or ctsd objects
% 
% INPUT: array of ts, tsd, or ctsds
%        find_max = specifies whether to take the minimum start time
%        in the array or the maximum start time. Default is false(0)
%        so pass in a non zero number if you want the maximum start
%        time returned.
%
% OUTPUT: a start time.

% cowen Fri Jul  2 16:21:36 1999
% cowen 2020 - simplified


ncells = length(ctsa_array);

st = nan(ncells,1);
for cellid = 1:ncells
    if ~isempty(ctsa_array{cellid})
        st(cellid) = min(ctsa_array{cellid});
    end
end
t = nanmin(st);
