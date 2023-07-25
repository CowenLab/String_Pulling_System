function h = subplot_ij(nr,nc,r,c,exp_x,exp_y)
% Just like subplot, except it lets you specify the particular row col
% index in the subplot from which to plot (instead of the single scalar
% index of subplot).
%function h = subplot_ij(nr,nc,r,c)
if nargin < 5
    exp_x = [];
end
if nargin < 6
    exp_y = [];
end

hh = subplot(nr,nc,sub2ind([nc nr],c,r));
if nargout > 0
    h = hh; % I have to do it this way so that it doesn't display h on the screen all of the time.
end

if ~isempty(exp_x)
    p = get(hh,'Position');
    p(3) = p(3) + exp_x; % this makes the figures wider.
    set(hh, 'Position', p);
end
if ~isempty(exp_y)
    p = get(hh,'Position');
    p(4) = p(4) + exp_y; % this makes the figures wider.
    set(hh, 'Position', p);
end
