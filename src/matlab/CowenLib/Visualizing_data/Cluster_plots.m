function Cluster_plots(TT_prefix, feature_name, target_cluster_ts, marker_spikes_ts_array, other_cluster_ts_array, save_extension, marker_colors, text_string)
%function Cluster_plots(TT_prefix, feature_name, target_cluster_ts, marker_spikes_ts_array, other_cluster_ts_array)
% 
% Generate an xy plot of cluster information based on the feature that the
% user specifies. Highlight a target cluster and also a subset of spikes
% within that cluster. If desired, also display spikes from other clusters.
% 
% presumes there are .fd files of the desired type in the current working
% directory.
%
% INPUT:
%   TT_prefix = prefix of the ntt file (e.g. 'Sc1')
%   feature_name = e.g. 'energy' or 'StdPC1'
%   target_cluster_ts = a VECTOR of timestamps - presumes that timestamps
%   are in 1/10 msec
%   marker_spikes_ts_array = spikes to highlight by drawing them as symbols
%   instead of points.
%   other_cluster_ts_array = other clusters to plot (a cell array of spike
%   time vectors)
%   save_extension = how to save the data (e.g. 'fig' 'png') if empty,
%      figures will not be saved.
%   marker_colors = could be a matrix of colors or color symbols
%   text_string = string to appear in the filename and title.
%
%  OUTPUT: 
%   plots of all 6 projections of the cluster. These plots are saved 
%
% cowen
%
% e.g.
% Cluster_plots('Sc1', 'energy', Stgt, Smarker, Sother, 'png')
% S = load_tfiles(ff);
if nargin < 6
    save_extension = [];
end
if nargin < 7
    marker_colors = { 'r' 'b' 'g' 'm' 'k' 'y' 'c' 'r' };
end
if nargin < 8
    text_string = [];
end

load ([TT_prefix '_' feature_name '.fd'],'-mat')

%symbols = {'rx' 'ko' 'g+' 'm*' 'kp' 'r^' 'b<' 'g>' };

other_colormap = jet;

tmp = linspace(1,Rows(other_colormap),length(other_cluster_ts_array))
tmp = round(tmp);
other_colormap = other_colormap(tmp,:);

[is,target_idx] = intersect(floor(FeatureTimestamps),floor(target_cluster_ts));
for iClust = 1:length(other_cluster_ts_array)
    [is,other_idx{iClust}] = intersect(floor(FeatureTimestamps),floor(other_cluster_ts_array{iClust}));
end

for iClust = 1:length(marker_spikes_ts_array)
    [is,marker_idx{iClust}] = intersect(floor(FeatureTimestamps),floor(marker_spikes_ts_array{iClust}));
end

for ii = 1:4
    for jj = ii:4
        if (ii~=jj)
            figure
            for iClust = 1:length(other_cluster_ts_array)
                plot(FeatureData(other_idx{iClust},ii),FeatureData(other_idx{iClust},jj),'.','MarkerSize',1)
                hold on
            end
            a = axis
            
            plot(FeatureData(:,ii),FeatureData(:,jj),'k.','MarkerSize',1)
            for iClust = 1:length(other_cluster_ts_array)
                plot(FeatureData(other_idx{iClust},ii),FeatureData(other_idx{iClust},jj),'.','MarkerSize',3,'Color',other_colormap(iClust,:))
            end
            plot(FeatureData(target_idx,ii),FeatureData(target_idx,jj),'.','MarkerSize',3,'Color',marker_colors{1})
            %k = convhull(FeatureData(target_idx,ii),FeatureData(target_idx,jj));
            %plot(FeatureData(target_idx(k),ii),FeatureData(target_idx(k),jj),'r','LineWidth',2)
            
            for iClust = 1:length(marker_spikes_ts_array)
                plot(FeatureData(marker_idx{iClust},ii),FeatureData(marker_idx{iClust},jj), '.','MarkerSize',5,'Color',marker_colors{iClust+1})                
            end
            
            xlabel([ feature_name ' Channel ' num2str(ii)])
            ylabel([ feature_name ' Channel ' num2str(jj)])
            axis(a)
            
            title([TT_prefix '  ' text_string])
            
            if ~isempty(save_extension)
                saveas(gcf,[TT_prefix '_' feature_name '_cluster_plot_Ch_' num2str(ii) 'x' num2str(jj) '_' text_string '.' save_extension]) 
            end
        end
    end
end
