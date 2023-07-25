function [C,evas,V,TS2] = Cluster_action_potentials_by_ISI(TS, varargin)
% Cluster APs based on their instantaneous firing rate.
% Why? Because bursts or intermediate states might just indicate unique
% bits of information. Currently, this is not much more than a slightly
% more complex burst-detector.
% This might be better than looking at local ISI - more information perhaps
% and not as distorted by huge ISI windows.
%
% I tested this on pyr cells in CA1- seems to work well with the parameters
% below and the vast majority of the time it clusters into 2 groups -
% bursting and not. Somtimes 3. This is a little slow given the IFR code.
%
% Cowen 2020
%
% Assumes seconds
% n = 5000;
% TS = .1*cumsum(abs(randn(n,1)) + double(rand(n,1)>.5).*(2.5+abs(randn(n,1))*5) );
up_lim_clust = 5;
bin_size_sec = 0.01;
smooth_win_bins = 10;
PLOT_IT = true;

Extract_varargin
V = []; evas = [];

if iscell(TS)
    C = [];
    TS2 = [];
    cnt = 1;
    % This is slow. parfor might help.
    for ii = 1:length(TS)
        % Currently this is nothing more than a burst detector - other than it
        % could potentially find more than 2 clusters - say of different IFR
        % states. It is encouraging though that it does a nice job and seems to
        % always find 2 clusters. What is nice is that this information could
        % span across bins
        [C{ii},evas{ii},~,tmp] = Cluster_action_potentials_by_ISI(TS{ii},'PLOT_IT',false);
        %         nc(ii) = e.OptimalK;
        for jj = 1:length(tmp)
            % treats each cluster as a 'new' cell.
            TS2{cnt} = tmp{jj};
            cnt = cnt + 1;
        end
    end
    
    
    return
    
end


TS = TS(:);
[~,Q,e,IF] = Instantaneous_Firing_Rate(TS,bin_size_sec,smooth_win_bins);
V = log(IF);
% % encode the ISI before and after each spike.
% I have not yet had much success doing the following. Clustering does not
% look good, but it could be something that I am doing. I think it gets
% distorted by huge ISIs. Probably need to do the log at the very least.
%  V(2:end,2) = log(diff(TS));
%  V(2:end-1,3) = log(diff(TS(2:end)));
%  V(:,4) = (V(:,2)-V(:,1))./nansum(V,2);

evas = evalclusters( V,'linkage','silhouette','KList',1:up_lim_clust); % so far silhouette is the winner. It uses ward by default.
C = evas.OptimalY;
if nargout > 3
    u = unique(C(~isnan(C)));
    TS2 = cell(1,length(u));
    for ii = 1:length(u)
        TS2{ii} = TS(C==u(ii));
    end
end
% evas = evalclusters( IF,'linkage','DaviesBouldin','KList',1:up_lim_clust); % so far silhouette is the winner. It uses ward by default.
% evas = evalclusters( V,'linkage','DaviesBouldin','KList',1:up_lim_clust); % so far silhouette is the winner. It uses ward by default.
% evas = evalclusters( V(:,3),'linkage','DaviesBouldin','KList',1:up_lim_clust); % so far silhouette is the winner. It uses ward by default.

% k_from_evalclusters_linkage(iS) = evas.OptimalK;
% C = clusterdata(IF,'MaxClust',evas.OptimalK);
% C = clusterdata(V,'MaxClust',evas.OptimalK);
if PLOT_IT
    %     figure
    %     subplot(1,2,1)
    %     plot(V(:,1),V(:,2),'.')
    %     subplot(1,2,2)
    %     histogram(V(:,3))
    figure
    histogram(C)
    
    figure
    gscatter(TS,ones(size(TS)),C)
    yyaxis right
    plot(e(1:end-1),Q)
end
