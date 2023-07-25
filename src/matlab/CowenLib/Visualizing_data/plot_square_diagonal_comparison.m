function hline = plot_square_diagonal_comparison(x,y,mkrstyle)
% Plots a diagonal lines square plot for comparing the point values in x
% and y.
%

if nargin < 3
    mkrstyle = 'b.';
end
h = plot(x,y,mkrstyle)
hold on
axis equal
%axis([min([x(:);y(:)]) max([x(:);y(:)]) min([x(:);y(:)]) max([x(:);y(:)])])
a = axis;
hl =  plot(a([1 2])', a([1 2])','r:')
% INSIDEOUS: DO NOT DO THIS AS IF YOU DO MULTIPLE PLOTS (EG HOLD ON) EVERYTHING WILL BE SCREWEED UP!!!
%set(gca,'XTick',get(gca,'YTick'))
axis square
axis tight
if nargout > 0
    hline  = hl;
end