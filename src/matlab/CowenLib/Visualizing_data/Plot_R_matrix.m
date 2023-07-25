function Plot_R_matrix(R, range)
% input - matrix of correlations. n x n
% PLot pretty plot
%
% Cowen 2022
if nargin < 2
    range = [];
end
mask = triu(ones(Rows(R)));
GIX = mask~=1;
% R = R.*~eye(Rows(R));
imagesc(1:Cols(R),1:Rows(R),R,'AlphaData',double(mask == 0));
set(gca,'color',[.85 .85 .85]);
% imagesc(1:Cols(R),1:Rows(R),R);
if isempty(range)
    range = prctile(R(GIX), [1 99]);
end
caxis(range);
% p = prctile(abs(R(GIX)), 95);
% caxis([]);

colormap(hotcold_colormap)
colorbar
axis square
xlabel('Neuron ID')
ylabel('Neuron ID')
pubify_figure_axis
title('Correlations (r)')
