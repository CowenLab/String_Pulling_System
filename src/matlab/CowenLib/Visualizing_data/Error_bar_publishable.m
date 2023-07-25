function h = Error_bar_publishable(x,y,e,font1Size,font2Size,xlabels, xlabeltxt,ylabeltxt,titletxt)
% An error bar plot that changes the font sizes/colors to be fancier-
% better for publication me thinks.
% cowen
h = bar(x,y,'FaceColor',[.8 .8 .8]);
hold on
errorbar(x,y,e,'k', 'LineStyle','none','Linewidth',2)
set(gca, 'xtickLabel',xlabels)
set(gca, 'FontSize',font1Size)
ylabel(ylabeltxt, 'FontSize',font2Size)
xlabel(xlabeltxt, 'FontSize',font2Size)
title(titletxt, 'FontSize',round(font2Size*1.4))
set(gca,'LineWidth',2)
box off
%h = gca;