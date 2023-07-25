function [x,y] = circle(npoints, radius)
% Returns the coordinates for points on a circle with npoints points and radius radius 
angle = linspace(0,2*pi,npoints +1);
y = sin(angle(1:end-1))*radius;
x = cos(angle(1:end-1))*radius;
