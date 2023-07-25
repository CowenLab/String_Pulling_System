function [h, he] = bare(mn,ci)
%function [h he] = bare(mn,ci);
% bar plot of means (matrix(vbls in each col) grouped by row) and 
% --> confidence intervals (cell array - one for each row of mn)
%
% INPUT: mn means - each row is a new group.
%        ci confidence interval - 2 rows (upper and lower) and as many cols
%           as elements in means.
% OUTPUT: graph. XDATA=get(get(h(i),'Children'),'XData');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen. 2007
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~iscell(ci)
    ci = {ci};
end
h = bar(mn);
ctrs = bar_centers(h);
hold on
if Rows(mn) == 1
    % Just one group.
    he = errorbarci(ctrs,mn,ci{1});
    set(he,'LineWidth',1);
else
    % Multiple groups (one for each row.)
    for ii = 1:length(ci)
        he(ii) = errorbarci(ctrs(:,ii)',mn(ii,:),ci{ii});
        set(he,'LineWidth',1);
    end
end
box off