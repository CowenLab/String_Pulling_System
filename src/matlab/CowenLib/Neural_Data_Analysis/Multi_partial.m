function [r , mean_r, std_r, rA, rB, rC,rB_A,rB_C,rA_C, M] = Multi_partial(A,B,C,interval_cols,...
    tet_id, show_images,bootstrap)
%function [p_r,rm_s1] = Multi_partial(A,B,C,interval_cols, on_same_tetrode)
% INPUT:
%    A,B,C : Cell by time (Q) matrices for each epoch A = S1, B = M, C = S2.
%    interval_cols : The interval size from which to compare Rm,s2|s1. Multi_partial will break up
%      the matrix in C into Cols(C)/interval_cols parts (call one part C_sub)
%      and compute the Rm_s2|s1 for each part individually. To be fair, A is also 
%      restricted to be the same size of C_sub (Cols(C)/interval_cols). This
%      is done by taking the last Cols(C)/interval_cols columns of A. This is done
%      because any reactivation or anti-reactivation or pre-activation could be caused
%      by the differneces in sampling resulting from differences in Q matrix sizes.
%    tet_id : a vector that provides the tetrode number for each cell in the A, B , and
%      C matrices. For instance, if the first 3 cells are from tetrode one, and the
%      last 2 from tetrode 4, then tet_id would be [1 1 1 4 4]. 
%    show_images = pass a 1 if you wish to view the r matrices.
%    bootstrap = if not 0 then bootstrap the corrcoef (sampling with replacement).
%
% OUPUT:
%    r(1:Cols(C)/interval_cols+1) where r(1) = r_B,A and r(2:end) =
%      the r for each interval (C_sub) in the C matrix. r is the partial
%      correlation coefficient, not the EV, which is r^2. Just square the r
%      to get the EV. (Warning about EV: it will give the illusion of pre-activation
%         because the value is squared-- so negative r values will always look positive)
%
%    mean_r = the mean value of the correlations in the r matrix. It is a 
%             vector of 3 elements: [ A_mean, B_mean, C_mean]
%    std_r = the std of the correlations in the r matrix. It is a 
%             vector of 3 elements: [ A_std, B_std, C_std]
%    rA,rB,rC = the cell by cell correlation matrices.
%    M = If specified, this is a matrix with cols: tet_id cellid1 cellid2 rB_A rB_C rA_C for all non-nan, non within tet correlations.
%
%

% cowen 4/20/01 Changed on_same_tet to simply be a vector of tetrode id's. Also
%       added the constraint that the cols of A and C_sub must be the same for
%       each analysis. See help for reasoning. Also returns the R matrices.
% cowen Thu Apr 15 16:17:26 1999
% adjusted a bit by Anne June 22
% This version throws out on same tet correls
% instead of zeroing them but still zeros
% out Nans from the corrcoef command
% Also, section which calcs the partial
% correl for S2 is commented out
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 6
    show_images = 0 ; % Useful for displaying the r matrices.
end
if nargin < 7
    bootstrap = 0 ; % Don't use bootstrapping by default.
end
% Use the shuffle time and shuffle cell bootstrap method
if bootstrap == 2
    % Reshuffle the C matrix.
end
M = [];

if nargin <= 4
    on_same_tet = [];
    on_same_tet_idx = [];
    
else
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Find indices in the cell by cell R matrix that indicate where correlations
    % between cells from the same tetrode reside so that these correlations can be
    % eliminated later.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if length(tet_id) ~= Rows(A)
        error('Tetrode id must be equal to the number of cells')
    end
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% N = the number of neurons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[N,c] = size(A);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the passed in interval_cols is greater than the total number of columns in C,
% then set the interval size to be the size of C.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
interval_cols = min([Cols(C),interval_cols]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If there are less columns in A than in a single interval
% of C, then the comparison is will not be entirely valid.
% If this is the case, warn the user. They should then pass
% in a larger Q matrix for A. If this is not possible, 
% one solution 'may' be to append on to A enough columns randomly
% selected from A to equal the length of an interval of C or decrease
% the size of C.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if interval_cols > Cols(A)
    disp('WARNING: A has less columns than the intervals of C.')
    disp(' Consider increasing the size of A. Multi partial will')
    disp(' reduce the size of the interval in C to be the same ')
    disp(' size as A.')
    interval_cols = Cols(A);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find the number of intervals in the C matrix for which the multi-partial
% will be computed. Also, use floor as we will not compute the partial 
% correlation for partial intervals.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
n_intervals = floor(Cols(C)/interval_cols);

if n_intervals == 0
    n_intervals = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute the NxN R matrices for the A and B Q matrices.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%rA  = full(corrcoef(A(:,1:(interval_cols-1))'));
rA  = full(corrcoef(A'));
rB  = full(corrcoef(B'));
rA(on_same_tet_idx) = inf; % Inf flages a within tetrode correlation.
rB(on_same_tet_idx) = inf; % Inf flages a within tetrode correlation.


if show_images
    figure
    subplot(1,n_intervals+2,1);imagesc(rA);title(['A r matrix ']);
    subplot(1,n_intervals+2,2);imagesc(rB);title(['B r matrix ']);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute the R for the C sub-matrices.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start_idx = 1;
for ii = 1:n_intervals
    if ii == n_intervals
        end_idx = Cols(C);
    else
        end_idx = start_idx + interval_cols - 1;
    end
    fprintf('.');
    rC{ii} = full(corrcoef(C(:,start_idx:end_idx)'));
    rC{ii}(on_same_tet_idx) = inf; % Inf flages a within tetrode correlation.
    if show_images
        subplot(1,n_intervals+2,ii+2);imagesc(rC{ii});title(['C r ' num2str(ii)])
    end
    start_idx = end_idx+1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the indices for the upper diagonal of the R matrix.
% The upper diagonal of A, B, and C will be converted into 
% a vector and compared via partial regression.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
idx = find(triu(ones(N,N))==0); % Must be 0, else you get the diagonal
[i,j] = find(triu(ones(N,N))==0); % Must be 0, else you get the diagonal
cA = rA(idx); % The upper diagonal converted to a vector
cB = rB(idx); % The upper diagonal converted to a vector
for interval = 1:n_intervals
    cC{interval} = rC{interval}(idx); % The upper diagonal converted to a vector
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set all Nans (where a vector had a length of 0) to 0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cA(find(isnan(cA))) = 0;
cB(find(isnan(cB))) = 0;
for jj = 1:n_intervals
    cC{jj}(find(isnan(cC{jj}))) = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Only consider non-Infs
% -- throw away stuff on same tetrode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f1 = find(isinf(cA)==0);
cA = cA(f1);
cB = cB(f1);

if nargout == 10
    i = i(f1);
    j = j(f1);
    M = [i(:) j(:) cA cB];
end

for jj = 1:n_intervals
    cC{jj} = cC{jj}(f1);
    if nargout == 10
        M = [M cC{jj}(f1)];
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute the correlations of the correlations for each interval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rB_C = zeros(n_intervals,1);
rA_C = zeros(n_intervals,1);
n_bootstraps = 100;
if bootstrap
    r = bootstrp(n_bootstraps,'corrcoef',cA,cB);
    rB_A = mean(r(:,2));
    stdrB_A = std(r(:,2));
else 
    r = corrcoef(cA,cB);
    rB_A = r(1,2);
end


for interval = 1:n_intervals
    if bootstrap
        r = bootstrp(n_bootstraps,'corrcoef',cC{interval},cB);
        rB_C(interval)  = mean(r(:,2));
        stdrB_C(interval)  = std(r(:,2));
        r = bootstrp(n_bootstraps,'corrcoef',cA,cC{interval});
        rA_C(interval)  = mean(r(:,2));
        stdrA_C(interval)  = std(r(:,2));
    else
        rB_C(interval) = diag(corrcoef(cC{interval},cB),1);
        rA_C(interval) = diag(corrcoef(cA,cC{interval}),1);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute the corrcoef (r) for m,s2|s1 for each interval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
r = zeros(1,n_intervals + 1);
r(1) = rB_A; % First element is not the partial. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The partial corrcoef calculation...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for interval = 1:n_intervals
    a = sqrt((1 - rB_A.^2).* (1 - rA_C(interval).^2));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % partial correlation coeff (r) of B_C|A, r^2 is the explained variance.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    r(interval+1) = (rB_C(interval) - rB_A.*rA_C(interval)) ./ a;
end					

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Provide some extra stats if desired
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargout > 1
    mean_r = mean([cA(:) cB(:)]);
    std_r = std([cA(:) cB(:)]);
    for ii = 1:n_intervals
        mean_r = [mean_r mean(cC{ii}(:))];
        std_r = [std_r std(cC{ii}(:))];
    end
end
