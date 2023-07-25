function o = colorbar_label(txt, width, location)
% inserts a colorbar and also places a label on the vertical axis.
% Width is a value which is the PROPORTion of the original colorbar withd.
% - so .5 means half width.
% Cowen
if nargin < 2
    width = [];
end
if nargin < 1
    txt = [];
end
if nargin < 3
%     location = 'eastoutside';
    location = 'east';
end
cax = caxis;
if any(isinf(cax))
    error('There are infinities in your color axis. Colorbar will not work with Infs in the color axis. Get rid of them.')
end

c = colorbar(location);
pos = get(c,'Position');
set(c,'Box','off');

c.AxisLocation= 'out';
pos(1) = .91;
pos(3) = .025;
pos(4) = .3;
set(c,'Position',pos)
c.Label.String = txt;
c.Label.FontSize = 8;
if ~isempty(width)
    % This is not working so well right now.
    ax = gca;
    axpos = ax.Position;
    cpos = c.Position;
    cpos(3) = width*cpos(3);
    c.Position = cpos;
%     ax.Position = axpos;
end

if nargout > 0
    o = c;
end
