function plot_diagonal_line(intercept, line_width, color)
%
if nargin < 1 
    intercept = [];
end
if nargin < 2 || isempty(line_width)
    line_width = 1.5;
end
if nargin < 3 
    color = 'k';
end
axis tight
axis equal
a = axis;
if isempty(intercept)
    intercept = min(a);
end

mn = intercept;
mx = max(a);
hold on
plot([mn mx],[mn mx],'Color',color,'LineWidth',line_width,'LineStyle',':')
% axis square
