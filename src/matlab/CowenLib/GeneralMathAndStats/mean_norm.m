function en = mean_norm(M)
% divide by mean of the cols.
en = M./(repmat(mean(M.*M),size(M,1),1)+eps);
