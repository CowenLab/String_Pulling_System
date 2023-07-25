function M = nan_to_val(M,v)
if nargin ==1 
    v = 0;
end
if length(v) == Cols(M)
    % Go by columns (for instnace, replace bad nans with the mean.
    for ii = 1:size(M,2)
        M(find(isnan(M(:,ii))),ii) = v(ii);
    end
else
    M(find(isnan(M))) = v;
end