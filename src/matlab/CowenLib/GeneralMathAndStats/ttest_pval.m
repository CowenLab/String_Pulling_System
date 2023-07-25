function [p,t] = ttest_pval(X,Y)
if nargin == 1
    [~,p,~,stats] = ttest(X);
else
    [~,p,~,stats] = ttest(X,Y);
end
t = stats.tstat;