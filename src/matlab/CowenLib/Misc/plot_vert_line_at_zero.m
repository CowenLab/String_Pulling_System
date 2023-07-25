function plot_vert_line_at_zero(varargin)
where_to_plot = 0;
color = [.5 .1 .4 ]; % 4th element sets transparency. 
style = ':';
line_width = 1.3;
axis_to_plot = 'x';
if length(varargin)==1
    where_to_plot = varargin{1};
    varargin = {'where_to_plot', where_to_plot};
end

Extract_varargin

a = axis;
hold on
for ii = 1:length(where_to_plot)
    switch axis_to_plot
        case 'x'
            plot([where_to_plot(ii) where_to_plot(ii)],a(3:4),'Color',color,'LineWidth',line_width,'LineStyle',style);
        case 'y'
            plot(a(1:2),[where_to_plot(ii) where_to_plot(ii)],'Color',color,'LineWidth',line_width,'LineStyle',style);
    end
end
