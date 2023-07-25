function [O, align_t] = PETH_Matrix(M, t, align_t, pts_before,pts_after)
% PETH - like - aligns matrices (not a single channel) on event points and
% returns a stacked 3D matrix.
% M = each col is a variable (e.g. freq band), each row is a sample.
BIX = align_t + pts_after > t(end) | align_t - pts_before < t(1);
align_t = align_t(~BIX);
ix = binsearch_vector(t,align_t);
ix = unique(ix);
ix = ix(ix > pts_before & ix < Rows(M)-pts_after);
O = nan(pts_before + pts_after+1,size(M,2),length(ix));
for iA = 1:length(ix)
    O(:,:,iA) = M((ix(iA)-pts_before):(ix(iA)+pts_after),:);
end
if nargout ==0
    figure
    imagesc(squeeze(mean(O,3)))
end
