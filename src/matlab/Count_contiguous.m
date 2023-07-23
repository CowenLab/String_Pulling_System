function [C,block_sizes,st,ed] = Count_contiguous(V)
% function [C,block_sizes] = Count_contiguous(V)
%
% Count the number of contiguous 1's or true's
% 
% Return a new vector C of same length as V that has the number of
% contiguous indicated for each element.
%
% V = [1 1 0 1 1 1 0 0 0 0 0 1 1 1 1 1 0 0 1];
% returns --->   2     2     0     3     3     3     0     0     0     0     0     5     5     5     5     5     0     0     1
% % fixed - logical could screw things up - so convert to singles.
% Cowen 2016
% Cowen 2019 - found that it fails with nans so fixed this.
%%%%%%%%%%%%%%%%%%%%%
V = double(V(:)'); % It must be a double or single - NOT a logical or this fails.
V(isnan(V)) = 0;
V(isinf(V)) = 0;

if min(V) < 0 || max(V) > 1
    error('Must be a vector of TF or 0,1')
end


d = diff([0 V]);

st = find(d > 0);
ed = find(d < 0); 
if length(st) > length(ed)
    ed(end+1) = length(V);
end
block_sizes = ed-st;
C = V;

if isempty(block_sizes)
    block_sizes = 0;
end

for ii = 1:length(st)
    C(st(ii):(ed(ii)-1)) = block_sizes(ii);
end

