function h = unsubplot(fh)
% INPUT: figure handle of the figure to unsubplot
% OUTPUT: The handles of unsubplotted figures.

% cowen

if nargin == 0
  fh = gcf;
end

for ii = 1:length(gf)
  figure
  copyobj(f,
  get(gf(ii),'Children')
end

