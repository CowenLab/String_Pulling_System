function [x,y] = draw_polygon(color)
% Draws a convex hull
if nargin ==0
    color ='g';
end
[x,y] = ginput_cowen;
% k = convexhull(x,y);
% x = x(k);  y = y(k);

hold on
plot(x,y,'Color',color)
