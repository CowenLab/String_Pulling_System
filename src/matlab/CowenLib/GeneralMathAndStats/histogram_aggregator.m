function [h] = histogram_aggregator(G, r)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function [h ] = histogram_aggregator(G,r)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% INPUT: 
%
% G = A 2 column matrix - first column is the minor group to histogram.
% the second column is the 'major group' for which to aggregate across.
% r = The range of values or classes of which to histogram acrosss.
%
% These results can then be averaged across the major group to compute the
% confidence intervals.
% 
% OUTPUT: mean, sd and a structure of other confidence estimate
% Cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

u2 = unique(G(:,2));
if nargin < 2
    r = unique(G(:,1));
end
h = zeros(length(u2),length(r));
for ii = 1:length(u2)
    ix = find(G(:,2)==u2(ii));
    if ~isempty(ix)
        h(ii,:) = hist(G(ix,1),r);
    end
end


if nargout == 0
    errorbar(mean(h), std(h));
end