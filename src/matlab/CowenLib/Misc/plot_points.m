function h = plot_points(points,symbol_color)
usable_symbols = {'b.','r.','g.','c.','k.','m.','y.'};
if nargin == 1
    symbol_color = 'b.';
end
if iscell(points)
    for ii = 1:length(points)
        h = plot_points(points{ii},usable_symbols{ii});
    end
else
    h = plot(points, ones(size(points)),symbol_color);
    hold on
end