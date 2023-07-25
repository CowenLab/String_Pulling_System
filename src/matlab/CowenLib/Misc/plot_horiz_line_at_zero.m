function plot_horiz_line_at_zero(where_to_plot, line_width, color, style)
%
if nargin < 1 || isempty(where_to_plot)
    where_to_plot = 0;
end
if nargin < 2 || isempty(line_width)
    line_width = 1.3;
end
if nargin < 3 
    color = [.4 .2 .2 .5];
end
if nargin < 4
    style = ':';
end
a = axis;
hold on
for ii = 1:length(where_to_plot)
    plot(a(1:2),[where_to_plot(ii) where_to_plot(ii)],'Color',color,'LineWidth',line_width,'LineStyle',style);
end
