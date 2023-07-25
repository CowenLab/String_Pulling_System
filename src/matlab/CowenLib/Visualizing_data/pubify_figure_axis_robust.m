function pubify_figure_axis_robust(fs1,fs2)

if nargin < 1
    fs1 = 10;
end
if nargin < 2
    fs2 = 12;
end

ax = findall(gcf,'Type','Axes');
tx = findall(gcf,'Type','Text');
txb = findall(gcf,'Type','TextBox');
% ln = findall(gcf,'Type','Line');

 
set(ax,'Box','Off');
set(ax,'LineWidth',2);
set(ax,'FontSize',fs1);


set(tx,'FontSize',fs2);

set(txb,'FontSize',12);

set(gca,'TickDir','out');
set(gca,'color','none')


% set(0,'DefaultAxesColor','none')




% set(ln,'LineWidth',1)