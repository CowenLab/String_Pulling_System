function h = plot_in_quadrant(line_to_plot, location, XY_size_ratio, colors, plotfun)
% function h = plot_in_quadrant(line_to_plot,location, XY_size_ratio, colors, plotfun)
% plots a figure in a quadrant of the current figure, regardless of what is
% already there. 
% NOTE: I just learned that a = axes('position',[left bottom width height])
% does nearly the same thing.
%
% e.g. plot_in_quadrant(mean(data),'upper_right',[.3 .3],'y')
if nargin < 3 |isempty(XY_size_ratio)
    XY_size_ratio = [.33 .33];
end
if nargin < 5
    plotfun = @plot;
end

if nargin < 4
    colors = {'b' 'r' 'g' 'k' 'c' 'y' 'm' 'b' 'r' 'g' 'k' 'c' 'y' 'm' 'b' 'r' 'g' 'k' 'c' 'y' 'm' };
end

if ~iscell(colors)
    colors = {colors};
end

hold on
a = axis;
width = a(2) - a(1);
height = a(4) - a(3);
switch lower(location)
    case 'upper_right'
        left_right_edge = [a(2) - width*XY_size_ratio(1) a(2)];
        bottom_top_edge = [a(4) - height*XY_size_ratio(2) a(4)];
        desired_width   = diff(left_right_edge);
        desired_height  = diff(bottom_top_edge);
    case 'upper_left'
        left_right_edge = [a(1)  a(1) + width*XY_size_ratio(1)];
        bottom_top_edge = [a(4) - height*XY_size_ratio(2) a(4)];
        desired_width   = diff(left_right_edge);
        desired_height  = diff(bottom_top_edge);
    otherwise
        error('wrong location code')
end
% Rescale the passed in image to fit into this new dimension.
x = linspace(left_right_edge(1),left_right_edge(2),length(line_to_plot));
% rescale the y axis and then fit it into the current range.
if size(line_to_plot,1) > 1
    nl = reshape(line_to_plot,1,size(line_to_plot,1)*size(line_to_plot,2));
    nl = standardize_range(nl,0.5) + .5; % puts it in the range of 0-1.
    nl = bottom_top_edge(1) + nl * height*XY_size_ratio(2);
    % Reshape back
    nl = reshape(nl,size(line_to_plot,1),size(line_to_plot,2));
else
    nl = standardize_range(line_to_plot,0.5) + .5; % puts it in the range of 0-1.
    nl = bottom_top_edge(1) + nl * height*XY_size_ratio(2);
end

for iL = 1:size(nl,1)
    if nargin < 3
        hh(iL) = plotfun(x,nl(iL,:));
    else
        hh(iL) = plotfun(x,nl(iL,:),'Color',colors{iL});
    end
end
if nargout == 1
    h = hh;
end