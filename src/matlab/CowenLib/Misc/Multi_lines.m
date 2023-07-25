function h = Multi_lines(X,Y,linprop)
if nargin == 2
  linprop = ''
end

for ii = 1:size(X,1)
  h = line(X(ii,:),Y(ii,:));
  set(h,'Color',linprop)
end
