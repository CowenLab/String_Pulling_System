function set_figure_width_height(wd, ht)
P = get(gcf,'Position');
set(gcf,'Position',[P(1:2) wd ht]);