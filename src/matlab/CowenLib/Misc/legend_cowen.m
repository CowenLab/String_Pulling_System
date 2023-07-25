function h = legend_cowen(varargin)
% pass in a cell array of things to put in the legend.
% I did this because the autoupdate thing was very frustrating.
if nargin == 1
    [h,icons] = legend(varargin{1});
else
    [h,icons] = legend(varargin);
end
set(h,'Interpreter','none');
set(h,'Autoupdate','off');
set(h,'Location','best');
set(h,'LineWidth',8);
set(h,'FontSize',14);
% [lgd,icons,plots,txt] 
legend boxoff;
% in theory, icons could be used to change the icon size for markers but in
% practice this does not work.
