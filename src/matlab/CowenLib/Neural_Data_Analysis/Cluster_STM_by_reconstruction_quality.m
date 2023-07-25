function [ClustID, INFO] = Cluster_STM_by_reconstruction_quality(STM, V)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ClustID = the ideal cluser identity for row in M.
% INFO = A structure that has cluster info - mean cluster centers,
% variance, n Cluster, clustering type, reconstruction accuracy.
% Cowen 2015
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
kmeans(STM,4);

for iK = 4:20
    
end