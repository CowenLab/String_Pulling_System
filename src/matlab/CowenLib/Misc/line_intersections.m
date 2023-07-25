function [x,y,direction] = line_intersections(x1,y1,x2,y2)
%function [x,y] = line_intersections(x1,y1,x2,y2)
% Given 2 functions, find the intersection points.
%  plot the functions if no output is provided.
% 
%  resolution depends on the resolution of the passed in vectors.
% cowen(2006)

% convert everything to the same x dimension
x = [];y=[];
if 0
    % Does not really help.
    % Restrict to the range of passed in data
    ix = find(x2 > x1(1) & x2 < x1(end));
    x2 = x2(ix); y2 = y2(ix);
    ix = find(x1 > x2(1) & x1 < x2(end));
    x1 = x1(ix); y1 = y1(ix);
end
nx = sort([x1(:);x2(:)]);
y1 = interp1(x1,y1,nx,'spline');
y2 = interp1(x2,y2,nx,'spline');
y1(isnan(y1)) = 0; y2(isnan(y2)) = 0;
% subtract
ys = y1-y2;
% find intersections
t = (ys(2:end)>0) - (ys(1:end-1)>0);
ix = find(abs(t) > 0);
x = nx(ix);
y = y1(ix);
direction = t(ix);
if nargout == 0
    %yss = (y1-y2)./(y1+y2);
    ix = find(direction > 0);
    subplot(2,1,1)
    plot(nx,y1,nx,y2,x,y,'.r',x(ix),y(ix),'.k');
    subplot(2,1,2)
    plot(nx(end:-1:1),cumsum(ys(end:-1:1)))
    xlabel('threshold')
end
