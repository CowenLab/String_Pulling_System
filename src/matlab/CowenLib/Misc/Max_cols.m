function m = Max_cols(C)
m = 0;
for ii = 1:length(C)
  s = size(C{ii},2);
  if s > m
    m = s;
  end
end
