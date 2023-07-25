function [local_entropy, time_ts, n_unique] = Sliding_entropy(A, window_size_bins, shift_bins, sliding_method,ignore_zeros)
%function [local_entropy, time_ts] = Sliding_entropy(A, window_size_bins, shift_bins, sliding_method)
% INPUT 
%  A - a matrix where the first column is time and the second column is the id of the word for each
%      point in time.
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
if nargin < 5
    ignore_zeros = 0;
end

[rows, cols] = size(A);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch sliding_method
case 'overlapping'
    n_shifts = floor((rows - window_size_bins) / shift_bins);
    local_entropy = zeros(n_shifts-1,1)*nan;
    time_ts = zeros(n_shifts-1,2)*nan;
    n_unique = zeros(n_shifts-1,1)*nan;
    for ii = 1:(n_shifts-1)
        %fprintf('.')
        
        start_idx_1 = ((ii-1) * shift_bins + 1);
        end_idx_1 = start_idx_1 + window_size_bins - 1;
        u = unique(A(start_idx_1:end_idx_1,2));
        n_unique(ii) = length(u);
        %n_possible = 2^n_cells_to_use;
        %n_unique/n_possible
        % Histogram over the states. This will give you some unique distribution for the period in question
        % Compare these distributions between periods.
        count = histcounts(A(start_idx_1:end_idx_1,2),u);
        %         count = histogram(A(start_idx_1:end_idx_1,2),u);
        if ignore_zeros && u(1) == 0
            pdist = count(2:end)/sum(count(2:end));
        else
            pdist = count/sum(count);
        end
        local_entropy(ii) = Entropy(pdist);
        time_ts(ii,1) = A(start_idx_1,1);
        time_ts(ii,2) = A(end_idx_1,1);
    end
    
otherwise
    error('incorrect method')
end
