function pubify_figure_axis(fsize1, fsize2, linewidth, minor_tics)
% Makes the axis publication ready.
% Cowen 2017
%
if nargin < 1 || isempty(fsize1)
    fsize1 = 12; % good for ppt
end

if nargin < 2 || isempty(fsize2)
    fsize2 = 14; % good for ppt
end

if nargin < 3 || isempty(linewidth)
    linewidth = 1.5; % good for ppt
    
end
if nargin < 4 || isempty(minor_tics)
    minor_tics = 'off';
end
% tlen = 0.015; % Tick Length

set(gca,'FontName','Arial')
box off
set(gca,'FontSize',fsize1); % This can screw up the x axis if its >= 12 and there are two cols in the figure.
set(get(gca,'YLabel'),'FontSize',fsize1)
set(get(gca,'XLabel'),'FontSize',fsize1)
set(get(gca,'Title'),'FontSize',fsize2)
% set(gca,'TickLength',[tlen tlen]); % make easier to read tics
set(gca,'LineWidth',linewidth)
set(gca,'XMinorTick',minor_tics)
set(gca,'YMinorTick',minor_tics)

set(gca,'TickDir','out'); % puts tics on the outside- cool.


if 0
    % if you would like to increase the tick resolution.
    g = gca;
    min_tics = 15;
    if length(g.XTick) < min_tics
        g.XTick = linspace(g.XTick(1),g.XTick(end),min_tics);
    end
end