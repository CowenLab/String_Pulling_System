function [OUT,idx] = intersect2(A,B)
% returns the values that correspond to the intersection between A and B. 
% it is different from matlab's intersect in that it will return repeated values.
% matlab doesn't bother returning the repeated vals, only the last repeated val.
% 
% INPUT; A,B two vector
% OUTPUT: The intersection between the vectors.
%   indices into A where the intersection was found.
idx = [];
for ii = 1:length(B)
    idx = [idx find(A == B(ii))];
end
OUT = A(idx);