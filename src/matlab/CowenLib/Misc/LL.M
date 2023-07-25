function ll(inpat)
% gives a directory list with file sizes
if nargin == 0
  inpat = '*';
end
d = dir(inpat);
for ii = 1:length(d)
  fprintf('%s\t %d \t %s\n',d(ii).name,d(ii).bytes,d(ii).date)
end