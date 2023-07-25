function norm_M = Normalize_matrix(M,type,option)
%
% Normalize by euclidean distance so that the length of each column
% vector is one or by z scores. euclidean is the default.
%
% INPUT: Matrix or vector to normalize
%        optional type if you want to normalize by z score.
%
% OUTPUT: Normalized matrix. Normalization is done by columns(the mean
%         or the vector length is computed from the column vectors that make
%         up the matrix..
%
%function M = Normalize_Matrix(M)
%


% cowen Wed Apr 28 11:46:40 1999

if nargin == 1
  type = 'euclidean';
end
[rows, cols] = size(M);

switch lower(type)
    case {'euclidean' 'energy'}
        norm_factor = sqrt(nansum(full(M).^2));
        norm_factor_matrix = repmat(norm_factor,Rows(M),1);
        norm_M = M./(norm_factor_matrix + eps);
    case {'z' 'z_scores'}
        Means = repmat(nanmean(M),rows,1);
        Stds = repmat(nanstd(M), rows,1);
        norm_M = (M-Means)./Stds;
    case 'standardize'
        norm_M = standardize_range(M);
    case 'data_distribution'
        % This is more novel - take each column, histogram it with
        % bootstrapping to get an estimate of the distribution. Smooth the
        % distribution or fit it to the function on p 247 of Exploratory
        % Analysis of Spatial and Temporal Data. Get the cumsum of this
        % distribution. Center the cumsum on 0. Multiply each point by its
        % associated value on the cumsum distribution. Jean-marc did
        % something like this.
        % This can work well with correlations as well - it will really
        % flatten them out
        norm_M = zeros(size(M));
        n_order = 7;  % 7 seems to work fine - 5 was a little sketchy on poisson data.
        KS = zeros(100,Cols(M));
        for iC = 1:Cols(M)
            [KS(:,iC),  xi] = ksdensity(M(:,iC));
        end
        KS = cumsum(KS);
        % Transform the original data. 
        for iC = 1:Cols(M)
            KS(:,iC) = KS(:,iC)/max(KS(:,iC)) - 0.5; % Scale to be between -1 and 1.
            p = polyfit(xi(:),KS(:,iC),n_order);
            % plot(xi(:),KS(:,iC),xi(:),polyval(p,xi(:)))
            norm_M(:,iC) = polyval(p,M(:,iC));
        end
    case 'by_cols'
        % Subtract the mean from some columsn.
        % this is seful of you are subtracting a fixation period.
        baseline = nanmean(M(option,:),1);
        baseline = repmat(baseline,Rows(M),1);
        norm_M   = M - baseline;
    otherwise
        error('incorrect type');
end

