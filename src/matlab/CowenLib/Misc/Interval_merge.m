function [I] = Interval_merge(I)
% ASSUMES you have a 2 col matrix of  start and end times
% merges the intervals so that intervals in which the end of one overlaps
% with the beginning of the next are merged.
%
% cowen
I = sortrows(I);
ix = 1;
while ~isempty(ix)
    d_times = I(1:end-1,2) - I(2:end,1);
    ix = find(d_times >= 0);
    if ~isempty(ix)
        I(ix,2) = I(ix+1,2);
        I(ix+1,:) = [];
    end
end
