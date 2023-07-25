function [x,y] = bar_centers(h)
% Return the centers and heights (troughs) of the bars from the bar handles
% (from the bar command). This is useful if you wish to plot error bars
% around bars. It is always difficult finding the bar centers.
%
% Get the offset of the second bar.
x = [];y = [];
for ii = 1:length(h)
    %    each handle in h is for one group in the bar plot (group is by color)
    y = [y; get(h(ii),'YData')];
    X = get(get(h(ii),'Children'),'XData');
    off = (X(4,:) - X(1,:))/2;
    ctr = X(1,:) + off;
    x = [x;ctr];
end
