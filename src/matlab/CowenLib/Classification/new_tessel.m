function N = new_tessel(M,step,rf_size,rows)
[rows,cols] = size(M);
N = zeros(rows-rf_size+1,rf_size*cols);

idx  = [];
for ii = 1:rf_size
  idx = [idx;[ii:(rows-rf_size+ii)]];
end

%D = [];
for ii = 1:cols
  % Use one cell.
  vN = M(:,ii);
  %D = [D,v(idx)'];
  N(:,(ii*rf_size-rf_size+1):ii*rf_size) = vN(idx)';
end
