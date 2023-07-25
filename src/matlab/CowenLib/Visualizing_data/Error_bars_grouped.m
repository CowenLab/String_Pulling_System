function [h]= Error_bars_grouped(mn,se)
% cowen - assumes just 2 groups for now.
nCols = size(mn,2);
h = bar(mn');
h(1).BarWidth = 0.9;
h(2).BarWidth = 0.9;
hold on
errorb((1:nCols)-.142,mn(1,:), se(1,:),'Color','k');
errorb((1:nCols)+.142,mn(2,:), se(2,:),'Color','k');
pubify_figure_axis
