function [M,S,Corr,msgstr] = Compare_epochs(TT1fn_root, TT2fn_root, CClust_ChannelValidity)
%
% INPUT: 
%      TT1fn_root, TT2fn_root : root filnames for the two epochs to compare.(i.e. 
%          the root of TT1_ep1.tt would be TT1_ep1 )
%      CClust_ChannelValidity : optional. indicates which tetrode channels to use.
%
% OUTPUT:
%      Summary figure that prints out the correlation coefficent matrix and the most
%          likely matches to the clusters in question.
%      M{1 and 2}{clusterid}, S{1 and 2}{clusterid} = the mean and std of all the features
%          for each cluster.
%      Corr = The entire correlation matrix between the two epochs
%      msgstr = a cell array of text that describes the most likely matches.
%
% NOTE: This routine loads TT1fn_root.cluster and TT1fn_root.tt 
%        
%function [M,S,Corr,msgstr] = CompareEnergy(TT1fn_root, TT2fn_root, CClust_ChannelValidity)
%
%

% cowen 9/25/99
%
if nargin == 2;
  CClust_ChannelValidity = [1:4]; % Channels to use
end
%----------------------------------------------------
% Load the .tt files...
%----------------------------------------------------
TT{1} = LoadTT([TT1fn_root '.tt']);
TT{2} = LoadTT([TT2fn_root '.tt']);
%----------------------------------------------------
% Load the cluster files...
%----------------------------------------------------
C{1}=load([TT1fn_root '.clusters'], 'MClust_Clusters', 'MClust_FeatureNames', '-mat');
C{2}=load([TT2fn_root '.clusters'], 'MClust_Clusters', 'MClust_FeatureNames', '-mat');
%----------------------------------------------------
% Calculate the features...
%----------------------------------------------------
nClusters{1} = length(C{1}.MClust_Clusters);
nClusters{2} = length(C{2}.MClust_Clusters);
nFeatures = length(C{1}.MClust_FeatureNames);
if length(C{1}.MClust_FeatureNames) ~= length(C{2}.MClust_FeatureNames)
  error('Different features used for each set. You are doomed to recalculate features.')
end
%----------------------------------------------------
% Go through each TT file and calculate the features.
%----------------------------------------------------
for tt_file = 1:length(TT)
  C{tt_file}.MClust_FeatureData =[];
  [featfilenames, ttChannelValidity] = FeatureFileNames(C{tt_file}.MClust_FeatureNames);
  for iF = 1:length(featfilenames)
    fprintf(2, 'Calculating feature:%i %s ... \n',tt_file ,featfilenames{iF});
    [nextFeatureData, nextFeatureNames] = ...
      feval(['feature_',featfilenames{iF}], TT{tt_file} , CClust_ChannelValidity);
    C{tt_file}.MClust_FeatureData = [C{tt_file}.MClust_FeatureData nextFeatureData];
  end
end
% Load in the .t files...
%

%TT1tfiles = FindFiles([TT1fn_root '_*.t']);
%TT2tfiles = FindFiles([TT2fn_root '_*.t']);
%S{1} = LoadSpikes(TT1tfiles);
%S{2} = LoadSpikes(TT2tfiles);
% Go through each cluster and print it out on a summary sheet.
%maxcols = max([length(TT1tfiles) length(TT1tfiles)]);
%----------------------------------------------------
% Calculate the mean and std of the features in each cluster for each epoch.
%----------------------------------------------------
for tt_file = 1:length(TT)
  % Mean
  M{tt_file} = zeros(nClusters{tt_file},size(C{tt_file}.MClust_FeatureData,2));
  % Std
  S{tt_file} = zeros(nClusters{tt_file},size(C{tt_file}.MClust_FeatureData,2));
  % Mahalanobis distance
  %D{tt_file} = zeros(nClusters{tt_file},size(C{tt_file}.MClust_FeatureData,2));
  for iClust = 1:nClusters{tt_file}
    % Find the index in the feature matrix for each cluster
    clustid{tt_file}{iClust} =  FindInCluster( C{tt_file}.MClust_Clusters{iClust}, C{tt_file}.MClust_FeatureData);
    % Calculate the mean and std for the features in each cluster.
    M{tt_file}(iClust,:) = mean(C{tt_file}.MClust_FeatureData(clustid{tt_file}{iClust},:));
    S{tt_file}(iClust,:) = std(C{tt_file}.MClust_FeatureData(clustid{tt_file}{iClust},:));
   % D{tt_file}(iClust,:) = M{tt_file}(iClust,:)std(C{tt_file}.MClust_FeatureData(clustid{tt_file}{iClust},:));
    
    fprintf('.')
  end
  fprintf('/')
end
%----------------------------------------------------
% Eliminate the time from consideration. This dangerously assumes 
% time is in column 9, but there is no way to get around it now.
%----------------------------------------------------
M{1}(:,9) = [];
M{2}(:,9) = [];
%----------------------------------------------------
% Find how correlated each cluster is to other clusters.
%----------------------------------------------------
%Corr = corrcoef([M{1}',M{2}']); %Using all features
%CorrE = corrcoef([M{1}(:,1:4)',M{2}(:,1:4)']); % Using just energy
CorrP = corrcoef([M{1}(:,4:8)',M{2}(:,4:8)']); % Using just peak
% Take the subsection of the matrix of interest...
Sub = CorrP(nClusters{1}+1:end, 1:nClusters{1}); % Epoch 2 vs Epoch 1

%----------------------------------------------------
% Find the maximum in the row and columns. Those that are maximum in 
% both rows and columns are considered matches.
%----------------------------------------------------
MaxC = max(Sub);
MaxR = max(Sub');
V1 = Sub == repmat(MaxC,size(Sub,1),1);
V2 = Sub == repmat(MaxR',1,size(Sub,2));
V3 = V1.*V2;
[epoch2,epoch1] = find(V3 == 1);
%----------------------------------------------------
% Create some text of the results.
%----------------------------------------------------
cnt = 1;
for ii = epoch1'
  msgstr{cnt} = sprintf('%s, cluster %i is closest to %s, cluster %i\n',TT1fn_root,ii,TT2fn_root,epoch2(cnt)); 
  cnt = cnt + 1;
end
%----------------------------------------------------
% Print out the results.
%----------------------------------------------------
figure
subplot(2,1,1)
imagesc(Sub);colorbar
xlabel([TT1fn_root ' Clusters'])
ylabel([TT2fn_root ' Clusters'])
title(['Comparing ' TT1fn_root ' to ' TT2fn_root ' (R values)'])
subplot(2,1,2)
axis off
g = text(0,0.5, msgstr);
set(g,'FontSize',10);

%----------------------------------------------------
%----------------------------------------------------
