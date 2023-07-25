function hout = imagesc_with_text(M,A,B)
% plots the imagesc graph with text numbers in each cell corresponding to
% the value in the input matrix.
% returns the indices to each text element.
% cowen.
if nargin == 1 
    string_mask = '%9.2f';
elseif nargin == 2
    string_mask = A;
end
imagesc(M)

axis xy
[r,c] = find(M);
for ii = 1:length(r)
    if ~isnan(M(ii))
        string = sprintf(string_mask,M(sub2ind(size(M), r(ii),c(ii))));
        h(ii) = text(c(ii)-.25,r(ii),string);
%         h(ii) = text(j(ii),i(ii),string);
    end
end
axis ij
if nargout == 1
    hout = h;
end
