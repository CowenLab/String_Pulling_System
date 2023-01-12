function [spd,acc] = LK_Speed_from_xy(t,x,y,thresh)
if nargin < 4
    thresh = [];
end
dx = [0;diff(x(:))];
dy = [0;diff(y(:))];
dt = [0;diff(t(:))];
dist = sqrt(dx.^2 + dy.^2);
spd = dist./dt;
% mark as artifact speeds that exceed some threshold.
if ~isempty(thresh)
   spd(spd > thresh) = nan; 
end

if nargout > 1
    acc = [0;diff(spd)];
end
