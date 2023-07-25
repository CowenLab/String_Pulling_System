function plot_scale_bar(x_size, y_size)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plots handy scale bars on figures. Give the size in axis units.
% Cowen 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DRAW_TEXT = true;
xlim = get(gca,'XLim');
ylim = get(gca,'YLim');
xrng = diff(xlim);
hold on
color = [.35 .35 .35];

if ~isempty(x_size)
    bot = xlim(1) + diff(xlim)/4;
    plot([bot bot + x_size],ylim([2 2]),'Color',color,'LineWidth',6)
    if DRAW_TEXT
        text(bot, ylim(2) - abs(ylim(2)*.15),num2str(x_size),'Color',color)
    end
end

if nargin > 1 && ~isempty(y_size)
    bot = ylim(2) - y_size;
    plot(xlim([1 1]),[bot bot + y_size],'Color',color,'LineWidth',6)
    if DRAW_TEXT
        text(xlim(1) + xrng*.04, bot + y_size/2,num2str(y_size),'Color',color)
    end
end
