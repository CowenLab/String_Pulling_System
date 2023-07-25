function plot_tics(times,color,offset,line_length)
% function plot_tics(times,color,offset,line_length)
% Plot vertical tics of a given color, offset on the y axis, and length (in
% y units)
%
% Cowen 2022
if nargin < 4
    a = axis;
    line_length = (a(4)-a(3))*.2;
end
if nargin < 3
    offset = 0;
end
if nargin < 2
    color = [1 0 0];
end

if iscell(times)
    clrs = lines(length(times));
    for ii = 1:length(times)
        plot_tics(times{ii},clrs(ii,:),ii - 1, 1) % assume length of 1 - one per row.
        hold on
    end
    return
end

line([times(:) times(:)]',[zeros(length(times),1) line_length*ones(length(times),1)]'+offset,'Color',color)
