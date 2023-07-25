function plot_ref_line(where_to_plot, varargin)
color = [.9 .1 .1 ]; % 4th element sets transparency. 
style = ':';
line_width = 1.3;
orientation = 'vert'; % 'horiz'
Extract_varargin

a = axis;
hold on
for ii = 1:length(where_to_plot)
    switch orientation
        case 'vert'
            plot([where_to_plot(ii) where_to_plot(ii)],a(3:4),'Color',color,'LineWidth',line_width,'LineStyle',style);
        case 'horiz'
            plot(a(1:2),[where_to_plot(ii) where_to_plot(ii)],'Color',color,'LineWidth',line_width,'LineStyle',style);
    end
end
