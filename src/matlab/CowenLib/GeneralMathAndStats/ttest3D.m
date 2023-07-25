function [h,significance,ci,t] = ttest3D(X,Y)
% Perform a ttest on multiple 2 d arrays (like stacked images) assuming the
% 3rd dimension is the trial.

Xr = reshape(X,size(X,1)*size(X,2),size(X,3));
Yr = reshape(Y,size(Y,1)*size(Y,2),size(Y,3));
[h,significance,ci,stats] = ttest2(Xr',Yr');
t = stats.tstat;
h = reshape(h',size(X,1), size(X,2));
h(find(h==0)) = nan;
significance = reshape(significance',size(X,1), size(X,2));
significance(find(significance==0)) = nan;
t = reshape(t',size(X,1), size(X,2));
t(find(t==0)) = nan;
ci = reshape(ci',size(X,1), size(X,2),2);