function h = patch_intervals(start_end_positions,color,alpha,y_max)
%function h = patch_intervals(start_end_positions,color,alpha)
% INPUT:
% start_end_positions = nx2matrix of start and end positions for the
% current axis.
% color is the color
% this function takes the confusion out of patch.
% 
% cowen 2019

if nargin < 2
    color = 'b';
end
if nargin < 3
    alpha = 0.5;
end
if nargin < 4
    y_max = [];
end

if isempty(start_end_positions)
    return
end

a = axis;
if ~isempty(y_max)
    a(4) = y_max;
end

x = [start_end_positions(:,1)';start_end_positions(:,1)';start_end_positions(:,2)';start_end_positions(:,2)'];
y = repmat([a([3 4]) a([4 3])]' ,1,size(x,2));
h = fill(x,y,color);
%set(h,'FaceColor',color);
set(h,'FaceAlpha',alpha);
% set(h,'EdgeColor',color);
set(h,'EdgeColor','none');
