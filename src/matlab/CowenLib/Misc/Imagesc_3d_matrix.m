function h = Imagesc_3d_matrix(x,y,M)
% call like imagesc but with a 3d M. Final dim is the item num.
if nargin == 1
    M = x;
    x = [];
    y = [];
end
nEl = size(M,3);
nCols = min([nEl 4]);
nRows = ceil(nEl/nCols);
for ii = 1:nEl
    h(ii) = subplot(nRows,nCols,ii);
    imagesc(x,y,squeeze(M(:,:,ii)))
end