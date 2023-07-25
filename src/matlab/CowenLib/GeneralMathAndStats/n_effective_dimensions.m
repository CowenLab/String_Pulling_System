function [Neff, nl] = n_effective_dimensions(M)
% Compute the number of effective dimensions in a matrix (Cols are
% variables, rows are samples).
% From Abbott Sampolinski 2009 Variability paper (no such paper!!)
%
% INPUT: n sample X n Variable matrix
% OUTPUT: number of effective dimensions
%         normalized eigenvalues. (divided by their sum so chunk of
%         explained variance).
%
% Cowen (2010)
IX = ~isnan(sum(M,2)); % Get rid of rows with Nans
if sum(IX) < 10
    % Too few trials to make any conclusions.
    nl = nan;
    Neff = nan;
else
    [~,~,latent] = pca(standardize_range(M(IX,:)));
    nl = latent./sum(latent);
    Neff = 1/(sum(nl.^2)+eps); %From Abbott 09
end