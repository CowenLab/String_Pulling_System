function [X,Y,notes] = ginput_cowen(end_point,enter_notes)
% same as ginput, but plots stars where you click so you know where you
% have clicked.
if nargin == 0 || isempty(end_point)
    end_point = inf;
end

if nargin < 2
    enter_notes = false;
end

point_count = 1;

a = axis;
hold on

if isinf(end_point)
    title('Hit ENTER to finish')
end
X = [];
Y = [];
notes = [];
a(1)
while point_count <= end_point
    %
    [x y] = ginput(1);
    if isempty(x) %|| (isinf(end_point) && x(1) < a(1))
        break
    end
        
    plot(x,y,'g*');
    hold on
    X(point_count) = x;
    Y(point_count) = y;
    
    if enter_notes
        notes{point_count} = inputdlg({'Enter Note'}); 
    end
    
    point_count = point_count + 1;

end
X = X(:);
Y = Y(:);