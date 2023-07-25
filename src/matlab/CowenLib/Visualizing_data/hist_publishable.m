function h = hist_publishable(c,b,fontsz,xlabeltxt,ylabeltxt,titletxt)
% A fancier version of hist that makes more publishable ready figures.
[y x]= hist(c,b);
h = bar(x,y,'FaceColor','k');
axis tight
box off
set(gca, 'FontSize',fontsz)
ylabel(ylabeltxt, 'FontSize',round(fontsz*1.4))
xlabel(xlabeltxt, 'FontSize',round(fontsz*1.4))
title(titletxt, 'FontSize',round(fontsz*2))
