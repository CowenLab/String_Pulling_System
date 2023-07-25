function O = Time_series_to_blocks(L, window_size, overlap)
% Breaks a continuous time series into blocks - so a window_size by
% n_blocks matrix. n_blocks =  fix((length(L)-overlap)/(window_size-overlap));
% % Adapted from cohen book.
if nargin < 3
    overlap = 0;
end
ncol = fix((length(L)-overlap)/(window_size-overlap));
colindex = 1 + (0:(ncol-1))*(window_size-overlap);
rowindex = (1:window_size)';
O = L(rowindex(:,ones(1,ncol))+colindex(ones(window_size,1),:)-1);