function a = equalize_axes(h,markers);
%function equalize_axes(h,markers)
% Makes all of the axes on various subplots or different figures the same. Just pass in the axis
% handles on the subplots and figures to equalize.
%
% input: a vector of axis handles.
% output: equalized axis handles.
%
% cowen 2014
equal_x = true; % Equalize the x axes.
if nargin == 0
    % Get the axes automatically.
    h = get(gcf,'Children');
end
if nargin < 2
    markers = [];
end

ax = zeros(length(h),4);
for iA = 1:length(h)
    try
        axes(h(iA));
        ax(iA,:) = axis;
    catch
        h(iA) = [];
        ax(iA,:) = [];
    end
end
nax = [min(ax(:,1)) max(ax(:,2)) min(ax(:,3)) max(ax(:,4)) ];
for iA = 1:length(h)
    a = axis;
    axes(h(iA));
    if equal_x
        axis(nax)
    else
        axis([ax(iA,1:2) nax(3:4) ])
    end
    if ~isempty(markers)
        if iscell(markers)
            plot_markers(markers{iA});
        else
            plot_markers(markers);
        end
    end
end