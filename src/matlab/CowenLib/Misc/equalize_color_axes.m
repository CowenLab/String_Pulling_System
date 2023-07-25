function nax = equalize_color_axes(h, cax)
%function equalize_axes(h,markers)
% Makes all of the axes on various subplots or different figures the same. Just pass in the axis
% handles on the subplots and figures to equalize.
%
% input: a vector of axis handles.
% output: equalized axis handles.
%
% cowen
if nargin < 2
    cax = [];
end

if nargin == 0
    % Get the axes automatically.
    h = get(gcf,'Children');
end
ax = zeros(length(h),2);
for iA = 1:length(h)
    axis(h(iA));
    subplot(h(iA));
    ax(iA,:) = caxis;
end
if isempty(cax)
    nax = [min(ax(:,1)) max(ax(:,2))];
else
    nax = cax;
end
    
for iA = 1:length(h)
    axes(h(iA));
    caxis(nax)
end