function [partial_r, out_times ]= Sliding_partial_r(A,B,C, times, window_size_bins, shift_bins, tet_id)
%function partial_r= Sliding_r(A, window_size_bins, shift_bins, tet_id, sliding_method)
%
% NOTE: I JUST REALIZED THAT THIS IS NOT THE PROPER WAY TO DO THIS. TO DO
% IT CORRECTLY, YOU NEED TO ALSO SAMPLE FROM A WITH INTERVALS OF THE SAME
% SIZE AS THE ONES YOU ARE WINDOWING OUT OF C, OTHERWISE, THE GREATER
% SAMPLING MAKES A ALWAYS LOOK BETTER THAN C IF C IS SMALL. THE PROPER WAY
% WOULD BE TO SUBSAMPLE FROM A AND AVERAGE ACROSS THE SUBSAMPLES AND USE
% THAT FOR THE COMPARISON WITH C. 
%
% INPUT 
% A - a matrix where each row is a point in time and each column is a variable.
% time - The real times for each row in C.
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
% NOTE: The compilied version is 3 times faster than the non compiled version BUT, the 
%  compiled version just spits out an empty matrix.
%

% cowen
if nargin <= 6
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
[rows, cols] = size(C);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the indices for the upper diagonal of the R matrix.
% The upper diagonal of C, B, and C will be converted into 
% a vector and compared via partial regression.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
idx = find(triu(ones(cols,cols))==0); % Must be 0, else you get the diagonal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now get rid of the indices of the correlations from 
% the same tetrodes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
idx = setdiff(idx, on_same_tet_idx(:));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
n_shifts = floor(( rows - window_size_bins + 1) / shift_bins);
partial_r = zeros( 1, n_shifts - 1) * nan;
rAB = Coeff_compare(A,B,idx);

%waitbar(0,'Please wait...') % This doubles the amount of time.
out_times = zeros( n_shifts - 1,2) * nan;
for ii = 1:(n_shifts)
    %fprintf('.') % This triples the amount of time.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Compare this window with its neighbor.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    start_idx_1 = ((ii-1)*shift_bins + 1);
    end_idx_1   = start_idx_1 + window_size_bins - 1;
    %  start_idx_2 = end_idx_1 + 1;
    %  end_idx_2   = start_idx_2 + window_size_bins - 1;
    rAC = Coeff_compare(A,C(start_idx_1:end_idx_1,:),idx);
    rBC = Coeff_compare(B,C(start_idx_1:end_idx_1,:),idx);
    
    partial_r.rBC_A(ii) = (rBC - rAB.*rAC) ./ sqrt((1 - rAB.^2).* (1 - rAC.^2));
    partial_r.rAB_C(ii) = (rAB - rAC.*rBC) ./ sqrt((1 - rBC.^2).* (1 - rAC.^2));
    partial_r.rAC_B(ii) = (rAC - rBC.*rAB) ./ sqrt((1 - rAB.^2).* (1 - rBC.^2));
    partial_r.rAB(ii) = rAB;
    partial_r.rBC(ii) = rBC;
    partial_r.rAC(ii) = rAC;
    
    out_times(ii,1) = times(start_idx_1);
    out_times(ii,2) = times(end_idx_1);
   
end
