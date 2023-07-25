function plot_nearest_neighbors(distance, limit, marker_lines)
%function plot_nearest_neighbors(distance, limit)
% distance = a square distance matrix
% limit = a minimum distnace limit for the data to plot
% OUTPUT:
%  a plot of the clusters closest to the cluster in question.
if nargin < 3
    marker_lines = [];
end
mn = min(distance(:));
plot(mn,0,'b.')
hold on
for ii = 1:size(distance,1)
    plot([mn limit], [ii ii],'b')
    [vals,idx] = sort(distance(ii,:));
    idx(find(vals > limit)) = [];
    vals(find(vals > limit)) = [];
%    text(mn,ii,num2str(ii))
    plot(vals,ii,'k.')
    for jj = 1:length(idx)
        if mod(jj,2) == 0
            factor = .2;
        else
            factor = -.2;
        end
        text(vals(jj),ii+factor,num2str(idx(jj)))
    end
    
end

set(gca,'YTick',1:size(distance,1))
set(gca,'YTickLabel',1:size(distance,1))
axis tight
a = axis;

for ii = 1:size(marker_lines,1)
    plot([marker_lines(ii) marker_lines(ii)],[a(3) a(4)],'r:')
end

xlabel('Distance')
ylabel('Cluster ID')
title('Nearest Neighbors')