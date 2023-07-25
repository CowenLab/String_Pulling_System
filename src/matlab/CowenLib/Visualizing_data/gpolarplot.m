function h = gpolarplot(theta, rho, grp, varargin)
% presumes grp is categorical data.
% like polarplot - but add cats.
% Cowen 2023
linespec = '.';
markersize = 4;
legend_on = false;

Extract_varargin;

if iscell(grp)
    grp = categorical(grp);
end

grp_names = unique(grp);
clrs = lines(length(grp));
h = zeros(length(grp_names),1);
for iG = 1:length(grp_names)
    IX = grp == grp_names(iG);
    h(iG) = polarplot(theta(IX), rho(IX), linespec, 'Color', clrs(iG,:), 'MarkerSize', markersize);
    hold on
end
if legend_on
    legend(grp_names); legend boxoff
end

axis tight

set(gca,'FontSize',12)
