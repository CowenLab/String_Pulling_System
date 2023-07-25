function V = Diag_of_corrcoef_matrix(C,offset)
% Returns points C matrix centered on the diagonal using circshift.
% cowen 2018
if nargin < 2
    offset = 0; %round(Cols(C)/2);
end

V = zeros(size(C));
for ii = 1:Rows(C)
    V(ii,:) = circshift(C(ii,:),[0, -1*ii + 1 + offset]);
end
