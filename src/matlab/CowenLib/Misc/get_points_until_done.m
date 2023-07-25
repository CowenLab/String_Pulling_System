function XY = get_points_until_done()
%
%
%
keep_going = true;
count = 1;
a = axis;
hold on
XY = [];
title('Click to left of axis to stop collecting points')
while keep_going
    tmp = ginput(1);
    if tmp(1) < a(1)
        keep_going = false;
    else
        
        plot(tmp(1),tmp(2),'r*')
        XY(count,:) = tmp;
        count = count  + 1;
    end
end
