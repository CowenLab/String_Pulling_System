function h = plot_markers(offsets, linewidth, text_labels, text_fontsize, colors, yshift)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function plot_markers(offsets,linewidth)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Displays vertical lines on the plot. For event time plotting.
% INPUT
%   offsets 2 col matrix of x position and marker ID - unique color give to
%   each id.
%   linewidth.
if isempty(offsets)
    return
end
if nargin == 1
    linewidth = 2;
end
if nargin < 3
    text_labels = [];
    text_fontsize = [];
end
if nargin < 4 || isempty(text_fontsize)
    text_fontsize = 10;
end
if nargin < 5 || isempty(colors)
    colors = {[.8 .8 .8],[.5 .5 .8],'y','g','m','r','b',[.4 .6 .9],'c','m','k','c','b','r','g','m','k','c','m','k','c','b','r','g','m','k','c','m','k','c','b','r','g','m','k','c','m','k','c','b','r','g','m','k','c','m','k','c','b','r','g','m','k','c','m','k','c','b','r','g','m','k','c','m','k','c','b','r','g','m','k','c','m','k','c','b','r','g','m','k','c'};
end

if ~iscell(colors)
    c = [];
    for ii = 1:Rows(colors)
        c{ii} = colors(ii,:);
    end
    colors = c;
end


if nargin < 6
    yshift = 0.055;
end

if min(size(offsets)) == 1
    offsets = [offsets(:) [1:length(offsets)]'];
end

if Cols(offsets) == 3
    % If you pass in start and end intervals, then plot a nice line that
    % connects them.
    INTERVALS = offsets;
    offsets = offsets(:,[1 3]);
else
    INTERVALS = [];
end


if min(offsets(:,2)) == 0
    offsets(:,2) = offsets(:,2) + 1;
end
a = axis;
y_range = diff(a(3:4));
x_range = diff(a(1:2));
shift_x = x_range*.01;
shift_y = y_range*yshift; % .055
%shift_y = 0;
%difftb = abs(diff(a(3:4)));
top = max(a(3:4));
bottom = min(a(3:4));
%top = top - difftb * .03;
%bottom = bottom + difftb * .03;
LINE_CODE_OR_PATCH_CODE = 2;
hold on
h = zeros(1,Rows(offsets));
for mc = 1:Rows(offsets)
    if ~isempty(linewidth)
        plot([offsets(mc,1) offsets(mc,1) ],[a(3) a(4)],'Color',colors{offsets(mc,2)},'LineWidth',linewidth)
       % plot([offsets(mc,1) offsets(mc,1) ],[a(3) a(4)],'k:','LineWidth',linewidth-1)
    end
    if ~isempty(INTERVALS)
        if LINE_CODE_OR_PATCH_CODE == 2
            plot([INTERVALS(mc,1) INTERVALS(mc,2)], [bottom bottom],'Color',colors{offsets(mc,2)},'LineWidth',20); %linewidth*8
        else
            patch_intervals([INTERVALS(mc,1) INTERVALS(mc,2)],colors{offsets(mc,2)},1,bottom + (top-bottom)*.2)
        end
    end
    
    if mc > 1
        if offsets(mc,2) == offsets(mc-1,2)
            %plot a line connecting these two regions. - Screw it, it gets
            if 1
                %messed up with axes and the like.
                if ~isempty(linewidth)
                    plot([offsets(mc-1,1) offsets(mc,1) ],[bottom bottom],'Color',colors{offsets(mc,2)},'LineWidth',linewidth)
                    plot([offsets(mc-1,1) offsets(mc,1) ],[bottom bottom],'k:','LineWidth',linewidth)
                    % Don't make it at the very top - otherwise the axis cuts it
                    % off.
                    plot([offsets(mc-1,1) offsets(mc,1) ],[top top],'Color',colors{offsets(mc,2)},'LineWidth',linewidth)
                    plot([offsets(mc-1,1) offsets(mc,1) ],[top top],'k:','LineWidth',linewidth)
                end
            elseif 0
                % WARNING: THIS HAS CAUSED SAVEAS TO CRASH MANY MANY TIMES
                %patch_intervals([offsets(mc-1,1) offsets(mc,1) ],[1 1 0],.12)
                patch_intervals([offsets(mc-1,1) offsets(mc,1) ],colors{offsets(mc,2)},1,1)
            elseif 0
                plot([offsets(mc-1,1) offsets(mc,1) ],[top top],'k')
                plot([offsets(mc-1,1) offsets(mc,1) ],[bottom bottom],'k')
            end
        end
    end
    if ~isempty(text_labels) 
        if length(text_labels) >= mc
            h(mc) = text(offsets(mc,1)+shift_x, a(4)-shift_y, text_labels{mc}, 'FontSize',text_fontsize,'FontWeight','bold','Rotation',90);%,'BackgroundColor',colors{offsets(mc,2)});
            %            'HorizontalAlignment','center',...
            % remember - set(h,'Rotation',90) will rotate the text 90 degrees.
        end
    end
end
return