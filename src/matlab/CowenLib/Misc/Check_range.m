function [O,idx] = Check_range(T)
%function O = Check_range(T)
%
% Check to see if all the cells in T are objects with the same range
% of values. All elements of T must be objects(ts, tsd...) or empty.
% 
% INPUT:
%        T - cell array of objects(ts, tsd ...)
%
% OUTPUT:
%        O - value of 1 if all of T have the same range, 0 if they do
%        not.
%
% cowen Fri Jul  2 18:38:39 1999
A = [];  
idx = []; % index of the aberrant object
cnt = 1;
O = 1;   % Default is that the ranges are equal.
% Find the first non empty element
while(~isempty(A) & cnt<length(T))
  cnt = cnt + 1;
end
A = Range(T{cnt},'ts');
[r,c] = size(A);
r
% Check from the first non_empty element onward
for ii = cnt+1:length(T)
  if ~isempty(T{ii})
    Tr = Range(T{ii},'ts');
    if size(Tr,1) ~= r | Tr ~= A
      size(Tr,1)
      idx = [idx;ii];
      O = 0;
    end
  end
end
