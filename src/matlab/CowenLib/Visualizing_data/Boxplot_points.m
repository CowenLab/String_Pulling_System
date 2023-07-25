function Boxplot_points(V,G, varargin)
% PLot a boxplot and overlay points. In format of data (V) and categorical
% group information (G). 
% Cowen 2019
MarkerSize = 8;
MarkerFaceAlpha = 0.6;

Extract_varargin;
if nargin == 1 || isempty(G)
    D = [];
    for iC = 1:Cols(V)
        D{iC} = V(:,iC);
    end
    [V,G] = group_data(D);
end


boxplot(V,G,'Notch','on','Whisker',1)
lines = findobj(gcf, 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', 'r');
hold on
u = unique(G);
for ii = 1:length(u)
    IX = G == u(ii);
    VV = V(IX);
    x = (rand(length(VV),1)-0.5)/4;
    scatter(x + ii, VV,MarkerSize,'k','filled','MarkerFaceAlpha',MarkerFaceAlpha);
end
pubify_figure_axis
p = anova1(V,G,'off');
title(sprintf('ANOVA p=%0.4f',p))
