function h = errorbar_group(d,g, varargin)
% plots errorbars for each group.
include_bar = true;
flip_order = false;
plot_points = true;
Extract_varargin;

if iscell(d)
    [d,g] = group_data(d);
end
names = cat2cell(unique(g));
[mn,se] = grpstats(d,g,{'mean','sem'});
if flip_order
    tmp = names;
    for ii = 1:length(names)
        tmp{length(names)-ii+1} = names{ii};
    end
    names = tmp;
    mn = mn(end:-1:1);
    se = se(end:-1:1);
end

if include_bar
    bar(mn)
    hold on
end


if plot_points
    hold on
    for ii = 1:length(names)
        pts = d(g==names{ii});
        x = repmat(ii,length(pts),1);
        x = x + (rand(size(x))-.5)*.2;
        plot(x,pts,'o','MarkerSize',8,'MarkerFaceColor',[.4 .4 .4],'MarkerEdgeColor',[.5 .1 .5])
    end
end

h = errorbar( mn, se, 'LineStyle', 'none','Color','k','LineWidth',3);
set(gca,'XTick',1:length(mn))
set(gca,'XTickLabel',names)


pubify_figure_axis;
