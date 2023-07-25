function [pairsx, pairsy] = Ginput_pairs(pause_it)
% Input pairs of values. Useful for entering start and end times.
%
% INPUT:
%    Optional minimal y value. If you hit the cursor below this value, the
%    function will terminate. Default is 0.
% OUTPUT:
%    A series of start and end points
%

% cowen 2017

%%
if nargin < 1
    pause_it = false;
end
cnt = 1;

hold on

pairsx =[];
pairsy =[];

while (1)
    x = [nan nan];
    if pause_it
        pause;
    end
    a = axis;
    ymin = a(3); ymax = a(4);
    xmin = a(1); xmax = a(2);
    %
    x = ginput(1);
    plot(x(1),x(2),'g>')
    hold on
    if x(2) < ymin || x(2) > ymax || x(1) < xmin || x(1) > xmax
        return;
    end
    pairsx(cnt,1) = x(1);
    pairsy(cnt,1) = x(2);
    x = ginput(1);
    if x(2) < ymin || x(2) > ymax || x(1) < xmin || x(1) > xmax
        return;
    end
    pairsx(cnt,2) = x(1);
    pairsy(cnt,2) = x(2);
    plot(pairsx,pairsy,'r<')
    cnt = cnt + 1;
end
