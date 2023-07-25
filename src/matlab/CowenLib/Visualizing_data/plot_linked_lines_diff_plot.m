function h = plot_linked_lines_diff_plot(M)
% A linked line difference plot.
% INPUT: A 2 column matrix where the first column is linked to values in
% the second column.
hh = plot([ones(size(M(:,1))) ones(size(M(:,1)))+1]',[M(:,1) M(:,2)]','.-','MarkerSize',28,'LineWidth',1,'Color','k');
a = axis;
a(1) = .75;
a(2) = 2.25;
axis(a);
set(gca,'XTick',[1 2])
[HYP,p] = ttest(M(:,1) - M(:,2));
%[p] = signrank(M(:,1) - M(:,2));
title(['p = ' num2str(p)])
if nargout >0
    h = hh;
end
pubify_figure_axis