function [r, R, Rv, Rvp] = Partial_r_react(A, B, C, tet_id, PARAMS)
%function [r, R] = Partial_r_react(A, B, C, tet_id, bootstrap, varargin)
% INPUT:
%    A,B,C : TIME(ROWS) by CELL(COLS) (transposed Q) matrices for each epoch. For instance, 
%            A = S1, B = M, C = S2.
%      ALTERNATIVELY, the user can pass in the R matrices and the EV will be computed using them. 
%
%    tet_id : a vector that provides the tetrode number for each cell in the A, B , and
%      C matrices. For instance, if the first 3 cells are from tetrode one, and the
%      last 2 from tetrode 4, then tet_id would be [1 1 1 4 4]. The actual numbers don't matter.
%      all that matters is that each cell is identified by a unique numbers. Order is important.
%
%    bootstrap (optional): default is 'none'. 
%                          'by_cell', bootstrap by varying the cells included in the R matrix. A vector is
%                               returned for each component in r. Each element corresponds to the value when
%                               the cell indicated by that element's index was removed from the analysis
%                          'by_r', bootstrap by the r values in the R matrix
%                          'by_cell_and_r', bootstrap by both cell and r matrix. Works by taking one
%                             cell out of the R matrices and recalculating the partial correlations.
%
%    arg 1 specifies the number of bootstraps for boot_by_r
%
%
%  Some hard coded parameters (for now, until I determine if they are
%  worthwhile or not... 
%
%   PARAMS.Remove_nonsig_corrs  Remove all correlations that are not significant.
%   PARAMS.Fisher_r_rescaling   Rescale the correlations to fisher z values.
%
%
% OUTPUT:
% 
%    Structures with the following values
% 
%    r.rAB    straight correlations - if bootstrapped, the value is the mean of the bootstrap.
%                                     if bootstrapped by cell, this is a vector of all of the correlations.
%    r.rBC
%    r.rAC
%    r.rAB_C  partial correlations  
%    r.rBC_A  
%    r.rAC_B  
%    r.rABp  - p values for the straight correlation. (see corr).
%    r.rBCp  
%    r.rACp  
%    
% 
%    R.A The R matrices used for the analysis. If bootstrapping by cell, only the last matrix used is provided
%    R.B
%    R.C
%
% The values of each of these correlations is a vector, one for each subset defined by interval.
% The R matrices are symmetric.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if size(A,1) ~= size(C,1)
    error('A and C must have the same number of samples -otherwise the comparison is unfair.')
end


if nargin < 5 | isempty (PARAMS)
    % Default specific parameters.
    PARAMS.Remove_nonsig_corrs =1; % Remove all correlations that are not significant during Behavior
    PARAMS.Fisher_r_rescaling = 1; % Rescale the correlations to fisher z values.
    PARAMS.Bootstrap = 'none' ; % Don't use bootstrapping by default.
end
%
if isempty(A) | isempty(B) | isempty(C)
    error('Do not pass in an empty matrix.')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% N = the number of neurons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[c,N] = size(A);
if nargin < 4
    tet_id = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% bootstrap determines the type of bootstrapping to do.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch PARAMS.Bootstrap
case 'none'
    % no bootstrapping
    boot_by_cell = 0;
    boot_by_r = 0;
    n_to_boot_by_cell = 1;    
case 'by_cell'
    boot_by_cell = 1;
    boot_by_r = 0;
    n_to_boot_by_cell = N;
case 'by_r'
    boot_by_cell = 0;
    boot_by_r = 1;
    n_to_boot_by_cell = 1;

    if nargin > 5
        n_to_boot_by_r = varargin{1};
    else
        n_to_boot_by_r = 100;
    end
case 'by_cell_and_r'    
    boot_by_cell = 1;
    boot_by_r = 1;
    n_to_boot_by_cell = N;
    n_to_boot_by_r = 100;

    if nargin > 5
        n_to_boot_by_r = varargin{2};
    end
otherwise
    error('Incorrect bootstrap parameter')
end

if isempty(tet_id)
    on_same_tet_idx = [];
end

if nargin < 4 
    on_same_tet_idx = [];
    tet_id = []; 
end

if ~isempty(tet_id)
    on_same_tet_idx = find_on_same_tet_idx(tet_id);
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute the NxN R matrices for the A and B Q matrices.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if size(A,1) == size(A,2) & size(B,1) == size(B,2)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % If the users passed in square matrices, then let's assume
    % they are the R matrices.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    R.A  = A;
    R.B  = B;
    R.C  = C;
else
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % We should do a shuffle correction at this point.
    %  Alternatively - we can work with the probabilities: Remove the
    %  correlations that are not significicantly different from 0 - they
    %  are not interesting.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    warning off % divide by 0 annoyance.
    [R.A ] = corr(A+eps);
    [R.B R.Bp] = corr(B+eps);
    [R.C ] = corr(C+eps);
    warning on
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Remove really unsignificant correlations - might not be much left
    % though.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if PARAMS.Remove_nonsig_corrs
        %R.A(find(R.Ap > 0.20)) = nan; % Nan will be converted to 0, perhaps they should be removed altogether (inf). Probably does not matter.
        R.B(find(R.Bp > 0.20)) = nan; % It's only really valid to remove the correlations that were non-significant during behavior.
        %R.C(find(R.Cp > 0.20)) = nan;
    end
end
% 
if PARAMS.Fisher_r_rescaling
    R.A = fisher_Z_score(R.A+eps);
    R.B = fisher_Z_score(R.B+eps);
    R.C = fisher_Z_score(R.C+eps);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%R.A  = real(log(R.A)); % log transforms so small correlations are not
%ignored. I found that this does not help. Perhaps that means that only the
%large correlations matter. See above Fisher Z transform.
%R.B  = real(log(R.B));
%R.C  = real(log(R.C));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

R.A(on_same_tet_idx) = inf; % Inf flages a within tetrode correlation.
R.B(on_same_tet_idx) = inf; % Inf flages a within tetrode correlation.
R.C(on_same_tet_idx) = inf; % Inf flages a within tetrode correlation.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If bootstrapping by cell, remove one cell from the R matrix (a row and column)
% This is much more efficient than removing the cell from the Q matrix.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for boot_no = 1:n_to_boot_by_cell
    A = R.A;
    B = R.B;
    C = R.C;
    if boot_by_cell
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Mark a cell for deletion.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        A(boot_no,:) = inf;
        A(:,boot_no) = inf;
        B(boot_no,:) = inf;
        B(:,boot_no) = inf;
        C(boot_no,:) = inf;
        C(:,boot_no) = inf;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get the indices for the upper diagonal of the R matrix.
    % The upper diagonal of A, B, and C will be converted into 
    % a vector and compared via partial regression.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    idx = find(triu(ones(N,N))==0); % Must be 0, else you get the diagonal as well as the off diag.
    cA = A(idx); % The upper diagonal converted to a vector
    cB = B(idx); % The upper diagonal converted to a vector
    cC = C(idx); % The upper diagonal converted to a vector
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set all Nans (where a vector had a length of 0) to 0
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    cA(find(isnan(cA))) = 0;
    cB(find(isnan(cB))) = 0;
    cC(find(isnan(cC))) = 0;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Only consider non-Infs
    % -- throw away stuff on same tetrode or the cell that is not
    %    included in this bootstrap.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    f1 = find(isinf(cA)==0);
    cA = cA(f1);
    cB = cB(f1);
    cC = cC(f1);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % compute the correlations of the correlations for each interval
    % Using corr instead of corrcoef as corr ignores nans -
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if boot_by_r
        rAB = nanmedian(bootstrp(n_to_boot_by_r,'corr',cA,cB));
        rBC = nanmedian(bootstrp(n_to_boot_by_r,'corr',cB,cC));
        rAC = nanmedian(bootstrp(n_to_boot_by_r,'corr',cA,cC));
    else 
        [rAB r.rABp] = corr(cA,cB);
        [rBC r.rBCp] = corr(cB,cC);
        [rAC r.rACp] = corr(cA,cC);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % partial correlation coeff (r) of B_C|A, r^2 is the explained variance.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    r.rAB_C(boot_no) = (rAB - rAC.*rBC) ./ sqrt((1 - rBC.^2).* (1 - rAC.^2));
    r.rBC_A(boot_no) = (rBC - rAB.*rAC) ./ sqrt((1 - rAB.^2).* (1 - rAC.^2));
    r.rAC_B(boot_no) = (rAC - rBC.*rAB) ./ sqrt((1 - rAB.^2).* (1 - rBC.^2));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % If bootstrapping by cell, store the current r value in a vector.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    r.rAB(boot_no) = rAB;
    r.rBC(boot_no) = rBC;
    r.rAC(boot_no) = rAC;
    if nargout <= 4
         idx = find(triu(ones(N,N))==0); % Must be 0, else you get the diagonal as well as the off diag.
         Rv = zeros(length(idx),4);
         Rv = [A(idx(:)) B(idx(:)) C(idx(:)) idx(:)];% The upper diagonal converted to a vector
    end
    if nargout == 4
        Rvp = [R.Ap(idx(:)) R.Bp(idx(:)) R.Cp(idx(:)) idx(:)];% The upper diagonal converted to a vector
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function on_same_tet_idx = find_on_same_tet_idx(tet_id)
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

return