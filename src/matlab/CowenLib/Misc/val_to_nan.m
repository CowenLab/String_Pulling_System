function M = val_to_nan(M,v)
if nargin ==1 
    v = 0;
end
M(find(M==v)) = nan;
