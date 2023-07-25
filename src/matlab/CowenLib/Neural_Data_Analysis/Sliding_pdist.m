function [local_pdist, time_ts] = Sliding_pdist(Q, times,window_size_bins, shift_bins, sliding_method)
%function [local_pdist, time_ts] = Sliding_pdist(Q, times,window_size_bins, shift_bins, sliding_method)
% INPUT 
%  Q
%
% window_size_bins
%  size of the window to shift.
% shift_bins
%  number of bins to shift after each comparison.
% tet_id 
%  the id of each variable in A. this is used to find cells from the R matrix and eliminate them
% sliding method 
%  overlapping specifies that overlapping chuncks of A will be compared with overlap specified by shift_bins
%
%
% cowen

if nargin < 4
    sliding_method = 'overlapping';
end


[rows, cols] = size(Q);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch sliding_method
case 'overlapping'
    n_shifts = floor((rows - window_size_bins) / shift_bins);
    local_pdist = zeros(n_shifts-1,1)*nan;
    time_ts = zeros(n_shifts-1,2)*nan;
    for ii = 1:(n_shifts-1)
        %fprintf('.')
        
        start_idx_1 = ((ii-1) * shift_bins + 1);
        end_idx_1 = start_idx_1 + window_size_bins - 1;
        local_pdist(ii) = mean(pdist(full(Q(start_idx_1:end_idx_1,:))));
        time_ts(ii,1)   = times(start_idx_1,1);
        time_ts(ii,2)   = times(end_idx_1,1);
    end
    
otherwise
    error('incorrect method')
end
