function [self_similarity, out_times ]= Sliding_r(A, times, window_size_bins, shift_bins, tet_id, sliding_method)
%function self_similarity= Sliding_r(A, window_size_bins, shift_bins, tet_id, sliding_method)
% INPUT 
% A - a matrix where each row is a point in time and each column is a variable.
% time - The real times for each row in A.
% window_size_bins
%  size of the window to shift.
% shift_bins
%  number of bins to shift after each comparison.
% tet_id 
%  the id of each variable in A. this is used to find cells from the R matrix and eliminate them
% sliding method 
%  adjacent specifies that neighboring (not overlapping) chunks of A, size window_size_bins will be compared.
%  overlapping specifies that overlapping chuncks of A will be compared with overlap specified by shift_bins
%
% NOTE: THe compilied version is 3 times faster than the non compiled version BUT, the 
%  compiled version just spits out an empty matrix.
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 5
    sliding_method = 'adjacent';
end
if nargin < 4
    shift_bins = window_size_bins;
end

if nargin <= 3
    on_same_tet = [];
    on_same_tet_idx = [];
else
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Find indices in the cell by cell R matrix that indicate where correlations
    % between cells from the same tetrode reside so that these correlations can be
    % eliminated later.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    st_ends = find(diff([999; tet_id(:) ;999])~=0);
    
    M = zeros(length(tet_id));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set the regions in the R matrix with conjuncions of within tetrode
    % neurons to inf. Inf is a marker that will be used to get the indices
    % of these regions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for ii = 1:length(st_ends)-1
        M(st_ends(ii):(st_ends(ii+1)-1),st_ends(ii):(st_ends(ii+1)-1)) = inf;
    end
    on_same_tet_idx = find(isinf(M));
    
end
[rows, cols] = size(A);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the indices for the upper diagonal of the R matrix.
% The upper diagonal of A, B, and C will be converted into 
% a vector and compared via partial regression.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
idx = find(triu(ones(cols,cols))==0); % Must be 0, else you get the diagonal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now get rid of the indices of the correlations from 
% the same tetrodes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
idx = setdiff(idx, on_same_tet_idx(:));
%error('1')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch sliding_method
case 't0_aligned'
    % align each comparison with T0.
    % This is a way to get a sense of the correlation time
    % between states.
    n_shifts = floor(( rows - 2 * window_size_bins + 1) / shift_bins);
    self_similarity = zeros( n_shifts, n_shifts - 1) * nan;
    out_times = zeros( n_shifts, 2) * nan;

    for aa = 1:n_shifts -1
        %waitbar(0,'Please wait...') % This doubles the amount of time.
        idx_count = 1;
        start_idx_1 = ((aa-1)*shift_bins + 1);
        %start_idx_1 = ((ii-1)*shift_bins + 1);
        end_idx_1   = start_idx_1 + window_size_bins - 1;
    
        for ii = aa:(n_shifts)
            %fprintf('.') % This triples the amount of time.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Compare this window with its neighbor.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            start_idx_2 = (ii)*shift_bins;
            end_idx_2   = start_idx_2 + window_size_bins - 1;
            
            self_similarity(aa,idx_count) = Coeff_compare(A(start_idx_1:end_idx_1,:),...
                A(start_idx_2:end_idx_2,:), idx);
            out_times(ii,1) = times(start_idx_1);
            out_times(ii,2) = times(end_idx_2);
            %waitbar(ii/n_shifts)
            idx_count = idx_count + 1;
        end
    end
case 'adjacent'
    n_shifts = floor(( rows - 2 * window_size_bins + 1) / shift_bins);
    self_similarity = zeros( 1, n_shifts - 1) * nan;
    %waitbar(0,'Please wait...') % This doubles the amount of time.
    out_times = zeros( n_shifts - 1,2) * nan;
    for ii = 1:(n_shifts)
        %fprintf('.') % This triples the amount of time.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Compare this window with its neighbor.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        start_idx_1 = ((ii-1)*shift_bins + 1);
        end_idx_1   = start_idx_1 + window_size_bins - 1;
        start_idx_2 = end_idx_1 + 1;
        end_idx_2   = start_idx_2 + window_size_bins - 1;
        
        self_similarity(ii) = Coeff_compare(A(start_idx_1:end_idx_1,:),...
            A(start_idx_2:end_idx_2,:), idx);
        out_times(ii,1) = times(start_idx_1);
        out_times(ii,2) = times(end_idx_2);
    
        %waitbar(ii/n_shifts)

    end
    
case 'overlapping'
    n_shifts = floor((rows - window_size_bins) / shift_bins);
    self_similarity = zeros(1,n_shifts-1)*nan;
    out_times = zeros( n_shifts - 1,2) * nan;

    for ii = 1:(n_shifts-1)
        %fprintf('.')
        
        % Compare this window with its neighbor.
        start_idx_1 = ((ii-1) * shift_bins + 1);
        end_idx_1 = start_idx_1 + window_size_bins - 1;
        start_idx_2 = ((ii) * shift_bins + 1);
        end_idx_2 = start_idx_2 + window_size_bins - 1;

        self_similarity(ii) = Coeff_compare(A(start_idx_1:end_idx_1,:),...
            A(start_idx_2:end_idx_2,:), idx);
        

        out_times(ii,1) = times(start_idx_1);
        out_times(ii,2) = times(end_idx_2);
   
    end
    
otherwise
    error('incorrect method')
end
