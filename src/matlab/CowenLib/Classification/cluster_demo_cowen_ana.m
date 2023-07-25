function O = cluster_demo_cowen_ana(nClusts)
% function O = cluster_demo_cowen_ana(nClusts)
% Cowen 2015
%% maps clustering performance for a range of embedded clusters.
O.k_of_min_chi2 = zeros(1,length(nClusts));
O.k_nBins2InRow_linkage = zeros(1,length(nClusts));
O.k_of_max_nBinsGreater2 = zeros(1,length(nClusts));
O.nEffDim = zeros(1,length(nClusts));
O.Cophenetic_CC =  zeros(1,length(nClusts));
O.prop_in_first_3comp = zeros(1,length(nClusts));
O.k_nBinsGreater2_linkage = zeros(1,length(nClusts));
O.k_from_NbClust = zeros(1,length(nClusts));
O.k_from_evalclusters_linkage = zeros(1,length(nClusts));
O.all_k_from_NbClust = zeros(length(nClusts),2);
O.all_k_from_evalclusters_linkage = zeros(length(nClusts),2);

for iC = 1:length(nClusts)
    [M{iC}, O.all_k_from_NbClust(iC,:),O.all_k_from_evalclusters_linkage(iC,:)] = cluster_demo_cowen(nClusts(iC));
    
    O.k_from_NbClust(iC) = median(O.all_k_from_NbClust(iC,:));
    O.k_from_evalclusters_linkage(iC) = median(O.all_k_from_evalclusters_linkage(iC,:));
    O.k_of_min_chi2(iC) = nanmedian(M{iC}{1}.k_of_min_chi2);
    O.k_nBins2InRow_linkage(iC) = nanmedian(M{iC}{1}.k_nBins2InRow_linkage);
    O.k_nBinsGreater2_linkage(iC) = nanmedian(M{iC}{1}.k_nBinsGreater2_linkage);
    O.k_of_max_nBinsGreater2(iC) = nanmedian(M{iC}{1}.k_of_max_nBinsGreater2);
    O.k_from_cutoff_1_linkage(iC) = nanmedian(M{iC}{1}.k_from_cutoff_1_linkage);
    O.nEffDim(iC) = nanmean(M{iC}{1}.nEffDim);
    O.Cophenetic_CC(iC) = nanmean(M{iC}{1}.Cophenetic_CC);
    O.prop_in_first_3comp(iC) = nanmean(M{iC}{1}.prop_in_first_3comp);
    fprintf('.');
end
O.nClusts = nClusts;
%%
vbls = {'k_from_evalclusters_linkage' 'k_nBins2InRow_linkage' 'k_nBinsGreater2_linkage' 'k_from_NbClust' 'k_of_min_chi2' 'k_from_cutoff_1_linkage' 'k_of_max_nBinsGreater2' 'Cophenetic_CC'};
for iV = 1:length(vbls)
    v = O.(vbls{iV}); ylab = vbls{iV}; %
    
    figure
    plot(O.nClusts,v,'o-','Linewidth',4)
    axis tight
    axis square
    hold on
    axis([O.nClusts(1) O.nClusts(end) O.nClusts(1) O.nClusts(end)])
    plot([O.nClusts(1) O.nClusts(end)],[O.nClusts(1) O.nClusts(end)],'r')
    xlabel('Actual Clusters');
    ylabel('Detected Clusters');
    pubify_figure_axis
    grid on
    title([vbls{iV}])
end
%% Plot other things that may not scale on the same plot
xlab = 'Actual Clusters';
v = O.nEffDim; ylab = 'nEffDim';
v = O.Cophenetic_CC; ylab = 'Cophenetic_CC';
% v = O.prop_in_first_3comp; ylab = 'prop_in_first_3comp';
v = log(v); ylab = ['log ' ylab];
x = O.nClusts;
x = log(x); xlab = ['log ' xlab];
figure
plot(x,v,'o-','Linewidth',4)
axis tight
axis square
hold on
ylabel(ylab);
xlabel(xlab);
pubify_figure_axis
grid on
title(['Clustering Performance: ' ylab])