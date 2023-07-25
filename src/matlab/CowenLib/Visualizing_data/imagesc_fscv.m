function imagesc_fscv(x_s,y,M,color_axis)
if nargin <4
    color_axis = [-4 6]; % should be a 2-3 ratio like -4/6.
end
% y = linspace(-1,1,Rows(M));
imagesc(x_s,y,M)
axis ij
colormap(colormap_fscv)
colorbar

if ~isempty(color_axis)
    caxis(color_axis)
end
set(gca,'YTickLabel','')
plot_vert_line_at_zero
xlabel('s')