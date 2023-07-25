function h = plot_boxes(x,y,w,param);
% function h = plot_boxes(x,y,w,param);
%
% Plots boxes centered at x and y with a width w.
% Each row in x is plotted.
%
% cowen 2009
if nargin < 4
    param = 'g';
end

x = x(:);
y = y(:);

X = zeros(length(x),2)*nan;
Y = zeros(length(y),2)*nan;

X(:,1) = x - w/2;  X(:,2) = x + w/2;
Y(:,1) = y - w/2;  Y(:,2) = y + w/2;

xs = [X(:,1) X(:,1) X(:,1) X(:,2) X(:,2) X(:,2) X(:,2) X(:,1)];
ys = [Y(:,1) Y(:,2) Y(:,2) Y(:,2) Y(:,2) Y(:,1) Y(:,1) Y(:,1)];
%
h = plot(xs',ys',param);

% h = zeros(Rows(xs),1);
% for ii = 1:Rows(xs)

%     hold on
% end
