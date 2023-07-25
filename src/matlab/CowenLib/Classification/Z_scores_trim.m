function Mz = Z_scores_trim(M,percent)
% Assumes a column matrix.
Mz = zeros(size(M));
for iC = 1:Cols(M)
    Mz(:,iC) = (M(:,iC) - trimmean(M(:,iC),percent))/trimstd(M(:,iC),percent); % simple and seems to work best - fewer false positives.
end
