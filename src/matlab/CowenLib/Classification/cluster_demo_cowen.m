function [SD, k_from_NbClust,k_from_evalclusters_linkage] = cluster_demo_cowen(nClusters)
% function [SD, k_from_NbClust,k_from_evalclusters_linkage] = cluster_demo_cowen(nClusters)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Test Clustering
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout == 0
    PLOT_IT = true;
else
    PLOT_IT = false;
end

if nargin < 1
    nClusters = 23;
end
nFeatures = 20; % or number of neurons - whatever
nSamplesTotal = 200;
% nSamplesTotal = [];
if isempty(nSamplesTotal)
    nSamplesPerCluster = 40;
else
    nSamplesPerCluster = round(nSamplesTotal/nClusters);
end
NoiseFactor = .2;
SparsityPortion = .4;
nToDelete = round(SparsityPortion*nFeatures);
% generate some random clusters.
C = rand(nClusters,nFeatures);
% For each cluster, generate a number of samples from each cluster.
V = zeros(nSamplesPerCluster*nClusters, nFeatures)*nan;
G = zeros(nSamplesPerCluster*nClusters,1)*nan;
for iC = 1:nClusters
    ed = iC*nSamplesPerCluster;
    st = ed - nSamplesPerCluster + 1;
    rn = randperm(nFeatures);
    M = repmat(C(iC,:),nSamplesPerCluster,1);
    %     M = M + rand(Rows(M), Cols(M))*NoiseFactor;
    M = M + randn(nSamplesPerCluster,nFeatures)*NoiseFactor;
    %     M(:,rn(1:nToDelete)) = 0 ;
    M(:,rn(1:nToDelete)) = randn(Rows(M),nToDelete)*NoiseFactor*.5;
    V(st:ed,:) = M;
    G(st:ed) = ones(nSamplesPerCluster,1)*iC;
end
r = randn(1,Cols(V)); % Change the mean rate for some neurons.
V = V + repmat(r,Rows(V),1); % add a baseline firing rate
V = abs(V);

%
% if PLOT_IT
figure
subplot(1,4,1:3)
imagesc(V);colormap(jet)
xlabel('Feature (neuron)')
ylabel('Sample')
pubify_figure_axis
subplot(1,4,4)
imagesc(G);colormap(jet)
ylabel('Cluster ID')
pubify_figure_axis
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nTries = 1;
SD = [];PCA = []; SDall = [];k_from_NbClust = zeros(1,nTries)*nan;k_from_evalclusters_linkage = zeros(1,nTries)*nan;
for iS = 1:nTries
    ix = randperm(Rows(V));
    C = NbClust_R(V(ix,:));
    k_from_NbClust(iS) = length(unique(C));
    %     C = clusterdata(V(ix,:),'linkage','ward','savememory','on','maxclust',10);
    %     C = clusterdata(Z_scores(V),'linkage','single','savememory','off','maxclust',10,'distance','mahalanobis');
    %      eva = evalclusters(V,'kmeans','gap','KList',[3:45]) %
    %     Takes too long to do this.
    %     k_from_evalclusters_kmeans(iS) = eva.OptimalK;
    rng('default');  % For reproducibility
    %     eva = evalclusters( V(ix,:),'linkage','CalinskiHarabasz','KList',[3:45]);
    %     evag = evalclusters( standardize_range(V(ix,:)')','linkage','gap','KList',[3:45]);
    %     k_from_evalclusters_linkage(iS) = evag.OptimalK;
    %     evas = evalclusters( standardize_range(V(ix,:)')','linkage','silhouette','KList',[3:45]);
    evas = evalclusters( V(ix,:),'linkage','silhouette','KList',[1:45]); % so far silhouette is the winner. It uses ward by default.
    k_from_evalclusters_linkage(iS) = evas.OptimalK;
    %     eva = evalclusters(V(ix,:),'gmdistribution','CalinskiHarabasz','KList',[3:45]); % SLOW
    %     k_from_evalclusters_gmdistribution(iS) = eva.OptimalK;
    [SD{iS},PCA{iS}] = Sliding_dynamics(V(ix,:),Rows(V),[],false,'ward');
end
% 
% if PLOT_IT
%     vbls = {'k_of_min_chi2' 'k_of_max_nBinsGreater2' 'k_nBinsGreater2_linkage' 'nEffDim' 'Rolls_Treves' 'prop_active' 'chi2_of_k' 'R_matrix_mn_r' 'prop_in_first_3comp' 'k_nBinsGreater2' 'Cophenetic_CC' };
%     
%     for ii = 1:length(vbls)
%         M = SD{1}.(vbls{ii});
%                 x = SDrip.Time_usec/(1e6*60); xlab = 's';
%         x = 1:Rows(M); xlab = 't';
%         figure(ii);clf
%         if Cols(M) == 1
%             plot(x,M,'LineWidth',4)
%         else
%             subplot(3,1,1:2)
%             imagesc(x,SD{1}.nKlusts,M');colormap(jet)
%             colorbar
%             ylabel('nClusts')
%             pubify_figure_axis
%             subplot(3,1,3)
%             plot_confidence_intervals(x, M')
%             hold on
%             plot(x,max(M'),'.-')
%             subplot(3,1,1:2)
%         end
%         title(['nClusts ' num2str(nClusters) ' ' vbls{ii}])
%         axis tight
%         xlabel(xlab)
%         ylabel(vbls{ii})
%         pubify_figure_axis
%         label_figure(mfilename)
%     end
% end
%%
%
% SD{1}.k_of_min_chi2
% SD{1}.k_of_max_nBinsGreater2
