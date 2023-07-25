function h = plot_markers_simple(offsets, axis_to_use, linewidth, colors,linestyle)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function h = plot_markers_simple(offsets, axis_to_use, linewidth, colors,linestyle))
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2 || isempty(axis_to_use)
    axis_to_use = 'x';
end
if nargin < 3
    linewidth = [];
end
if nargin < 4
    colors = [];
end
if nargin < 5
    linestyle = '-';
end
if isempty(colors)
    colors = [.2 .6 .2];
%     colors = [1 1 1];
end
if isempty(linewidth)
    linewidth = 2;
end
if ~iscell(colors)
    clr = colors;
    colors = [];
    for ii = 1:length(offsets)
        colors{ii} = clr;
    end
end
if min(size(offsets)) == 1
    offsets = offsets(:);
end
a = axis;
hold on
for ii = 1: Rows(offsets)

    switch axis_to_use
        case 'x'

            plot(offsets([ii ii],1), a([3 4]),'Color',colors{ii},'LineWidth',linewidth,'LineStyle',linestyle)
            plot(offsets([ii ii],1), a([3 4]),'Color','w','LineWidth',1,'LineStyle',':')
            
            if Cols(offsets) > 1
                plot(offsets([ii ii],2), a([3 4]),'Color',[.8 .2 .2],'LineWidth',linewidth,'LineStyle',linestyle)
                plot(offsets([ii ii],2), a([3 4]),'Color','w','LineWidth',1,'LineStyle','--')
            end
        case 'y'
            plot(a([1 2]),offsets([ii ii]),'Color',colors{ii},'LineWidth',linewidth,'LineStyle',linestyle)

    end
end
