function O = Rebin_matrix(M,n_bins,agg_type);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function O = Rebin_matrix(M,n_bins,agg_type);
% Goes through each column in the matrix and sums up every n_bins (adds the
% values). The new values then become the points in a new matrix that is
% n/n_bins the number of rows as the original.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 2011.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3
    agg_type = 'sum';
end
bin_edges = 1:n_bins:(Rows(M)+1);

O = zeros(length(bin_edges)-1,Cols(M))*nan;
switch agg_type
    case 'sum'
        % The new bin is just the count of the contents of the old bins.
        for iR = 1:(length(bin_edges)-1)
            O(iR,:) = nansum(M(bin_edges(iR):(bin_edges(iR+1)-1),:));
        end
    case 'mean'
        % The new bin is the average of the old bins.
        for iR = 1:(length(bin_edges)-1)
            O(iR,:) = nanmean(M(bin_edges(iR):(bin_edges(iR+1)-1),:));
        end
    otherwise
        error('Incorrect type of aggregator')
end