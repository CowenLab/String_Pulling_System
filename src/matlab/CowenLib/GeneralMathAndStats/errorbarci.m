function h = errorbarci(x,m,ci,varargin)
%function h = errorbarci(x,m,ci,varargin)
% Errorbar with confidence interval - easier for standard ci calculations.
% Call just like errorbar, but used upper and lower confidence intervals.
% cowen
% If the user only passes in a single row for ci then assume the upper and
% lower confidence intervals are identical.
if size(ci,1) ==1
    ci = [ci;ci];
end
if nargin < 4
    h2 = errorbar(x,m,m-ci(2,:),ci(1,:)-m,'r.','MarkerSize',.001);
else
    h2 = errorbar(x,m,m-ci(2,:),ci(1,:)-m,varargin{:});
end
set(h2,'Marker','none')
if nargout > 0
    h = h2;
end
box off