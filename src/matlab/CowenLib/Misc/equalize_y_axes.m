function equalize_y_axes(h, lims)
%function equalize_y_axes(h,markers)
% Makes all of the y axes on various subplots or different figures the same. Just pass in the axis
% handles on the subplots and figures to equalize.
%
% input: a vector of axis handles.
%
% cowen 2014
if nargin < 2
    lims = [];
end
if nargin < 1 || isempty(h)
    h =get(gcf,'children');
end
cnt = 1;
hh = [];
a = [];

for ii = 1:length(h)
    if h(ii) ~= 0 && strcmpi(h(ii).Type,'axes')
        a(cnt,:) = axis(h(ii));
        hh(cnt) = h(ii);
        cnt = cnt + 1;
    end
end
h = hh;
for ii = 1:length(h)
    subplot(h(ii));
    ax = axis(h(ii));

    if isempty(lims)
        ax(3) = min(a(:,3));
        ax(4) = max(a(:,4));
    else
        ax(3:4) = lims;
    end
    axis(ax);
end
