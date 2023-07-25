function O = circshift_matrix(C,shifts)
O = nan(size(C));
for ii = 1:Cols(C)
    O(:,ii) = circshift(C(:,ii),1*shifts(ii));
end