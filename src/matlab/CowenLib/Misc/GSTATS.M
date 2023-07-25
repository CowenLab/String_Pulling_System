function [m,s,md,up,lp,groups] = gstats(X, G);
%function [m,s,md,up,lp,groups] = gstats(X, G);
%
% Group means of cols in X grouped by vector G which has the same number of 
% rows as X.
%
%

groups = unique(G);
c = size(X,2);
m  = zeros(length(groups),c);
s  = zeros(length(groups),c);
md = zeros(length(groups),c);
up = zeros(length(groups),c);
lp = zeros(length(groups),c);

for ii = 1:length(groups)
    idx = find(G == groups(ii));
    m(ii,:) = mean(X(idx,:));
    s(ii,:) = std(X(idx,:));
    if nargout > 2
        md(ii,:) = median(X(idx,:));
        up(ii,:) = prctile(X(idx,:),95);
        lp(ii,:) = prctile(X(idx,:),5);
    end
end