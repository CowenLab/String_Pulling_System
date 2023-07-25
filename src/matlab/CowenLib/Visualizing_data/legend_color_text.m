function h = legend_color_text(label_ca, color_ca, font_size, location, spacing_factor);
%function h = legend_color_text(label_ca, color_ca, font_size, location)
%
% INPUT: cell array of text labels to put on the plot
%        cell array of colors {'r' [0 0 255]}
%        font size: e.g. 8
%        position: 'top left' or 'bottom left'
%        spacing_factor - how much space between legends (the number of
%        slots on the y axis for labels so the smaller (e.g. 4), the wider
%        the spacing.
%
% OUPUT: A color coded legend with the text background being the color of
% the label (upper left quadrant default)
%
% Cowen 2009
forecolor = 'w';
if nargin < 2 || isempty(color_ca)
    color_ca = Colors;
end
if nargin < 3 || isempty(font_size)
    font_size = 8;
end
if nargin < 4
    location = 'top right';
end
if nargin < 5
    spacing_factor = 1.1; % .
end

if isnumeric(color_ca)
    tmp = [];
    for iR = 1:size(color_ca,1)
        tmp{iR} = color_ca(iR,:);
    end
    color_ca = tmp;
end

a = axis;
nLabels = length(label_ca);
spacing = (a(4) - a(3))/4/length(label_ca);% spacing_factor; % should squeez it into the upper 1/4 of hte plot?
spacing = spacing*spacing_factor;
spacing_x = (a(2) - a(1))/30;
%d = (a(4) - a(3))/6;
%v = linspace(a(4),a(4)-d,nLabels);
switch location
    case 'bottom left'
        x = a(1);
        v = a(3) + spacing;
        factor = 1;
    case 'top left'
        x = a(1);
        v = a(4) - spacing;
        factor = -1;
    case 'top right'
        x = a(2) - (a(2) - a(1))/5;
        v = a(4) - spacing;
        factor = -1;
    case 'bottom right'
        x = a(2) - (a(2) - a(1))/5;
        v = a(3) + spacing;
        factor = 1;
    otherwise
        error('Incorrect location parameter')
        
end
h = cell(nLabels,1);
for ii = 1:nLabels
    h{ii} = text(x + spacing_x, v, label_ca{ii}, 'HorizontalAlignment','left','BackgroundColor',color_ca{ii},'Color',forecolor,'FontWeight','bold','FontSize',font_size);
    v = v + spacing*factor;
end