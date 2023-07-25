function ViewClusters1Page(maxperfig)
% Summarize information about the clusters that are currently loaded into
% memory. 
%
% INPUT: none
% OUTPUT: A plot of waveform, isi, and autocorrelation as well as some 
%         summary stats on each individual cluster, conveniently placed 
%         in one figure for easy comparison.
%
% See also CompareClust if you want to compare clusters from different epochs.

% cowen 9/25/99.
global MClust_TTfn
global MClust_Clusters
global MClust_TTData
global MClust_FeatureData

% Clever way to extract the filname.
xx = strtok(MClust_TTfn(end:-1:1),filesep);
fname = xx(end:-1:1);
if nargin == 0
   maxperfig = 8;        % max number of clusters allowed on a single figure.
end
subtractor = 0;         % This is used to reset the number of clusters on a figure.
figure; orient landscape
len = min([maxperfig, length(MClust_Clusters)]); % number of clusts on current figure.
counter = 0;

% iterate through each cluster.
for iClust = 1:length(MClust_Clusters)
   % Print a new figure if the current one is overcroweded.
   if mod(iClust-1, maxperfig) == 0
      figure; orient landscape
      subtractor = counter * maxperfig;
      counter = counter + 1;
   end
   % Get the indices for the elements in the current cluster from the raw data.
   f = FindInCluster(MClust_Clusters{iClust}, MClust_FeatureData);
   if ~isempty(f)
      clustTT = ExtractCluster(MClust_TTData, f);
      % Plot the cluster
      CheckClusterByCol(['Cluster ', num2str(iClust)], clustTT, ...
         StartTime(MClust_TTData), EndTime(MClust_TTData),len,iClust - subtractor); 
	end
end
drawnow