function [T,INFO] = Hierarchial_clustering(X, maxclust, method)
% function [T,INFO] = Hierarchial_clustering(X, maxclust, method)
%
RUN_EVALCLUSTERS = true; % slow.

if length(maxclust) > 1
    nClusters = maxclust;
    maxclust = max(maxclust);
else
    nClusters = 1:maxclust;
end
INFO.nClusters = nClusters;
% [~,sc] = pca(X);
INFO.k_from_evalclusters_linkage_sil = nan;
INFO.k_from_evalclusters_linkage_stdrdized_sil = nan;
if RUN_EVALCLUSTERS
    try
        evas = evalclusters( X,'linkage','silhouette','KList',nClusters); % so far silhouette is the winner.
        %         [~,ix] = nanmax(evas.CriterionValues(2:end));
        H = hist(evas.OptimalY,unique(evas.OptimalY));
        nCl = sum(H > 2); % you need 3 or more observations to really be considered a cluster.
        if nCl< nClusters(end);
            INFO.k_from_evalclusters_linkage_sil =nCl;
        else
            INFO.k_from_evalclusters_linkage_sil =nan;
        end
    end
    
    %     try
    %         evas = evalclusters( standardize_range(X')','linkage','silhouette','KList',nClusters); % so far silhouette is the winner.
    %         [~,ix] = nanmax(evas.CriterionValues(2:end));
    %         INFO.k_from_evalclusters_linkage_stdrdized_sil = nClusters(ix+1);
    %     end
end
% It may be a good idea to chose the min for clusters GREATER than say 1 or
% 2
%
switch method
    case 'ward'
        % In practice, this does not seem to work as well.
        Y = pdist(X,'euclidean'); % seuclidean cos %NOTE - I had very interesting results when i clustered OVER Neuron/TIME!!!! The other direction What would this mean.
        Z = linkage(Y,'ward'); % note, a default in the literature is ward distance (also default in NbClust in R.
    case 'single'
        Y = pdist(X,'correlation'); % seuclidean cos %NOTE - I had very interesting results when i clustered OVER Neuron/TIME!!!! The other direction What would this mean.
%         Y = pdist(X,'seuclidean'); % seuclidean cos %NOTE - I had very interesting results when i clustered OVER Neuron/TIME!!!! The other direction What would this mean.
%          Z = linkage(Y,'single'); % This is now failing in simulation.
warning off
         Z = linkage(Y,'ward'); % note, a default in the literature is ward distance (also default in NbClust in R.
         warning on
end
INFO.coph = cophenet(Z,Y); % A measure of the quality of clustering. Higher the better.
Tmaxclust = cluster(Z,'maxclust',maxclust); % this is the cutoff - but it is so arbiraryr
Tcutoff = cluster(Z,'cutoff',1); % this is the cutoff - but it is so arbiraryr but it is more consistent that maxclust
%         IXmx = T == mode(T);
H = hist(Tmaxclust,unique(Tmaxclust)); % Seems like too many clusters generated for large matrices.
% Hp = 100*(H/sum(H)); % XXX
% INFO.k_nBinsGreater2_linkage = sum(Hp>0.5); % XXX you need .5% of samples to be considered a cluster.
INFO.k_nBinsGreater2_linkage = sum(H>2); % you need .5% of samples to be considered a cluster.
H = hist(Tcutoff,unique(Tcutoff)); % Seems like too many clusters generated for large matrices.
% Hp = 100*(H/sum(H));
INFO.k_from_cutoff_1_linkage = sum(H>4); % you need .5% of samples to be considered a cluster.
hh = zeros(max(H),1);
for ii = 1:max(H)
    hh(ii) = sum(H>ii);
end
% Find 2 in a row in which there was no change in the cluster
% count.
d = diff(hh);
ix = find(d ==0,1,'first')+1;
if ~isempty(ix)
    INFO.k_nBins2InRow_linkage = hh(ix);
else
    INFO.k_nBins2InRow_linkage = nan;
end
expected = ones(size(H))*mean(H);
INFO.chi2_of_k_linkage = sum((H-expected).^2./expected); % Chi square formula. This is not a measure of the number of clusters. In fact, I think the goal would be to have a low Chi square - it would indicate that there are more clusters - more evenly spread out.
%         max_Clust = min([round(Rows(Qa))/2 INFO.nKlusts]);
%     tic
INFO.chi2_of_k= zeros(1,length(nClusters))*nan;
INFO.entropy= zeros(1,length(nClusters))*nan;
INFO.nBinsGreater2= zeros(1,length(nClusters))*nan;
for iK = 1:length(nClusters)
    nK = nClusters(iK);
    
    if nK < Rows(X)/2;
        T = cluster(Z,'maxclust',nK);
%         T = kmeans(X,nK);
        %             c = inconsistent(Z);
        H = hist(T,1:nK);
        Hp = H/sum(H);
        expected = (ones(size(H))*sum(H))/nK;
%         expected_p = expected/sum(expected);
        % Compute measures of the number of clusters observed.
        INFO.chi2_of_k(iK) = sum((H-expected).^2./expected); % Chi square formula. This is not a measure of the number of clusters. In fact, I think the goal would be to have a low Chi square - it would indicate that there are more clusters - more evenly spread out.
%         INFO.chi2_of_kp(iK) = sum(abs(Hp-expected_p)); % 
        %             INFO.CV_Hist_of_k(iWin,iK) = std(Hp)/mean(Hp); % A measure of variance of the distribution. Similar to CHi square. Sensitive to outliers
        INFO.entropy(iK)= -sum(Hp.*log2(eps+Hp)); % forumula for entropy.
        %         INFO.scaled_entropy(iK)=  INFO.entropy(iK)/nClusters(iK);
        INFO.nBinsGreater2(iK) = sum(H>2);
    end
end
%
[~,ix] = nanmin(INFO.chi2_of_k);
INFO.k_of_min_chi2 = nClusters(ix); % This is the most reliabl in simulation.
%         [~,ix] = max(INFO.scaled_entropy(iWin,:));
%         INFO.k_of_max_scaled_entropy(iWin) = nClusters(ix);
[~,ix] = nanmax(INFO.nBinsGreater2);
INFO.k_of_max_nBinsGreater2 = nClusters(ix);
%         [~,ix] = max(INFO.CV_Hist_of_k(iWin,:));
%         INFO.k_of_max_CV_Hist_of_k(iWin) = nClusters(ix);
if nargout == 0
    figure
    subplot(2,1,1);plot(T,'o');axis tight;subplot(2,1,2);imagesc(X')
end
