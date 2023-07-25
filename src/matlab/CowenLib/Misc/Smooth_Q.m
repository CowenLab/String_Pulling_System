function M = Smooth_Q(Q, smoothfctr, type)
%function Q = Smooth_Q(Q, smoothfctr)
%
% INPUT: A raw Q matrix of spikes by time
%        A smoothing factor. Default is hamming. Decimate is an option.
%
% OUTPUT: A smoothed Q matrix
%
if nargin <= 2
  type = 'hamming'
  if nargin == 1
    smoothfctr = 3;
  end
end

its_sparse = 0;

if issparse(Q)
  its_sparse = 1;
  Q = full(Q);
end

[rows, cols] = size(Q);
switch type
  case 'hamming'
    M = zeros(size(Q));
  case 'decimate'
    M = zeros(rows,ceil(cols/smoothfctr));
  otherwise
    error('barf')
end

for ii = 1:rows
  switch type
    case 'hamming'
      M(ii,:) = Smooth_vel(Q(ii,:), smoothfctr);
    case 'decimate'
      M(ii,:) = decimate(Q(ii,:), smoothfctr);
    otherwise
      error('Incorrect type');
  end
end

if its_sparse
  Q = sparse(Q);
end