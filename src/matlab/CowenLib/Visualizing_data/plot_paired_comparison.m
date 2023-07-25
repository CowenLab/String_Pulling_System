function h = plot_paired_comparison(M)
% function h = plot_paired_comparison(M)
% Plot the typical plot for a paired series of data.
% Each column is assumed to be a variable. Only 2 columns allowed.
% cowen
xx = plot(M','.-','MarkerSize',26);
set(gca,'XTick',[1 2])
a=  axis;
a(1) = .8;
a(2) = 2.2;
axis(a);
if nargout == 1
    h = xx;
end
pubify_figure_axis
