function [X Y] = rotateXY(X,Y,radians)
% rotate by radians and return new rotated coordinates.
%
% see http://kwon3d.com/theory/transform/rot.html
RXY = [cos(radians) sin(radians); -sin(radians) cos(radians)]*[X(:) Y(:)]';
RXY = RXY';
X = RXY(:,1);
Y = RXY(:,2);