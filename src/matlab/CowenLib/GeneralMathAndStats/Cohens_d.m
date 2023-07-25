function d = Cohens_d(x,y)
if nargin == 1
    d = nanmean(x)/nanstd(x);
else
    d = (nanmean(x) - nanmean(y))/sqrt((nanstd(x)^2+nanstd(y)^2)/2);
%     d = (nanmean(x) - nanmean(y))/mean([nanstd(x) nanstd(y)]); % this
%     looks right but it isn't 
end
