function S = Fill_Nans_with_interpolants(S)
% For each column, find the nans and replace with a linear interpolant.
for iC = 1:Cols(S)
    IX = isnan(S(:,iC));
    ix = find(IX);
    ix_to_get = find(~IX);
    if ~isempty(ix_to_get)
        S(ix,iC) = interp1(ix_to_get,S(ix_to_get,iC),ix);
    end
end
