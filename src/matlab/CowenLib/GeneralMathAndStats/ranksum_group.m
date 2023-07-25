function [p,h,stats] = ranksum_group(V,G)
U = unique(G);
if length(U) > 2
    error('must only have 2 groups')
end
for iG = 1:length(U)
    v{iG} = V(G==U(iG));
end
if length(v) < 2
    p = nan;h = nan; stats= nan;
else
    [p,h,stats] = ranksum(v{1},v{2});
end