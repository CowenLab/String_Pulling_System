function [OUT, v, six]= sort_matrix(M,sort_type,param)
% Resorts matrix by peak or trough or pdist. 
% INPUT: M = matrix to sort (row = sample, col = param)
%        sort_type = how to sort('peak')
%        param = 1) used for kmeans - number of clusters OR, of sort_type = 'by_value' 
%        then this is the value upon which the matrix is sorted.
%
% OUTPUT: resorted matrix.
% Cowen 2021 - updated the kmeans to work with big-column matrices.
if nargin < 2
    sort_type = 'peak';
end
if nargin < 3
    param = [];
end

six2 = ones(Rows(M),1); % A second sort index if you need it.
switch(lower(sort_type))
    case {'mean'}
        [six] = nanmean(M,2);
%         [~,six] = sort(mn);
    case {'peak' 'max'}
        [mx,six] = max(M,[],2);
    case {'by_value'}
        six = param;
    case {'trough' 'min'}
        [mx,six] = nanmin(M,[],2);
    case 'sparsity'
        six = Density(M')';
    case {'pc1','pc2'}
        IX = ~isnan(sum(M));
        [~,score] = pca(M(:,IX));
        if isempty(score)
            disp('PCA failed')
            six = 1:Rows(M);
            six = six(:);
        else
            six = score(:,1);
            if strcmpi(sort_type,'pc2')
                six = score(:,2);
            end
        end
    case 'pdist'
        six = clusterdata(M,1);
    case 'kmeans'
        [~,six2] = max(M,[],2); % Have the sort within the cluster be the peak.
%         [~,six2] = min(M,[],2); % Have the sort within the cluster be the peak.
        if nargin < 3
            param = 3;
        end
        % pca and kmeans can't handle NANs
        MM = M;
        MM(isnan(MM)) = 0;
        if Cols(M) > Rows(M)
            [~,sc] = pca(MM);
            six = kmeans(sc(:,1:min(round([Cols(M)/2 Rows(M)/2]))),param);
        else
            six = kmeans(MM,param);
        end
        
end
v  = sortrows([six'; 1:Rows(M);six2']',[1 3]);
OUT = M(v(:,2),:);
