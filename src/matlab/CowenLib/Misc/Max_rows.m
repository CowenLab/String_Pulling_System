function m = Max_rows(C)
m = 0;
for ii = 1:length(C)
  s = size(C{ii},1);
  if s > m
    m = s;
  end
end
