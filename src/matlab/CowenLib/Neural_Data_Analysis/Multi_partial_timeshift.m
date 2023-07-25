function [r , mean_r, std_r, rA, rB, rC,rB_A,rB_C,rA_C] = Multi_partial_timeshift(A,B,C,...
    n_timeshifts , tet_id, show_images , bootstrap)
%function [p_r,rm_s1] = Multi_partial_timeshift(A,B,C,interval_cols, on_same_tetrode)
% INPUT:
%    A,B,C : time by cell (Q') matrices for each epoch A = S1, B = M, C = S2.
%    tet_id : a vector that provides the tetrode number for each cell in the A, B , and
%      C matrices. For instance, if the first 3 cells are from tetrode one, and the
%      last 2 from tetrode 4, then tet_id would be [1 1 1 4 4]. 
%    show_images = pass a 1 if you wish to view the r matrices.
%    bootstrap = if not 0 then bootstrap the corrcoef (sampling with replacement).
%
% OUPUT:
%    r where r(1) = r_B,A and r(2) = r_B_C, partialling out r_A
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

[r,nCells] = size(A);

if nargin <= 4
    on_same_tet = [];
    on_same_tet_idx = [];
else
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Find indices in the cell by cell R matrix that indicate where correlations
    % between cells from the same tetrode reside so that these correlations can be
    % eliminated later.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    st_ends = find(diff([999; tet_id(:) ;999])~=0);
    
    M = zeros(nCells);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set the regions in the R matrix with conjuncions of within tetrode
    % neurons to inf. Inf is a marker that will be used to get the indices
    % of these regions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for ii = 1:length(st_ends)-1
        M(st_ends(ii):(st_ends(ii+1)-1),st_ends(ii):(st_ends(ii+1)-1)) = inf;
    end
    on_same_tet_idx_w_diag = find(isinf(M));
    M(1:nCells+1:end) = 0;
    on_same_tet_idx_no_diag = find(isinf(M));
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% N = the number of neurons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if Rows(A) <  Rows(C)
    disp('WARNING: A has less rows(time) than the intervals of C.')
    disp(' Consider increasing the size of A. Multi partial will')
    disp(' reduce the size of the interval in C to be the same ')
    disp(' size as A.')
    C = C(1:Rows(A),:);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute the NxN R matrices for the A and B Q matrices.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
AllrA  = full(corrcoef(Shifted(A,n_timeshifts)));
AllrB  = full(corrcoef(Shifted(B,n_timeshifts)));
AllrC  = full(corrcoef(Shifted(C,n_timeshifts)));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create a r matrix for each of the timeshifts.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cA = []; cB = []; cC = [];
for timeshift = 1:(n_timeshifts+1)
    
    startidx = timeshift*nCells - nCells + 1;
    endidx   = startidx + nCells - 1;
    
    rA = AllrA(1:nCells,startidx:endidx);
    rB = AllrB(1:nCells,startidx:endidx);
    rC = AllrC(1:nCells,startidx:endidx);

    if timeshift == 1
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Get the indices for the upper diagonal of the R matrix.
        % The upper diagonal of A, B, and C will be converted into 
        % a vector and compared via partial regression.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        rA(on_same_tet_idx_w_diag) = inf; % Inf flages a within tetrode correlation.
        rB(on_same_tet_idx_w_diag) = inf; % Inf flages a within tetrode correlation.
        rC(on_same_tet_idx_w_diag) = inf; % Inf flages a within tetrode correlation.

        idx = find(triu(ones(nCells,nCells))==0); % Must be 0, else you get the diagonal
        cA = rA(idx); % The upper diagonal converted to a vector
        cB = rB(idx); % The upper diagonal converted to a vector
        cC = rC(idx); % The upper diagonal converted to a vector
    else

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % For the rest, you want to preserve the diagonal as this contains important
        % information about burst behavior (how correlated firing at t0 is to t1 of 
        % a particular cell.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        rA(on_same_tet_idx_no_diag) = inf; % Inf flages a within tetrode correlation.
        rB(on_same_tet_idx_no_diag) = inf; % Inf flages a within tetrode correlation.
        rC(on_same_tet_idx_no_diag) = inf; % Inf flages a within tetrode correlation.
        
        cA = [cA; rA(:)];
        cB = [cB; rB(:)];
        cC = [cC; rC(:)];
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set all Nans (where a vector had a length of 0 (acutally a std of 0 is sufficient
% to create nans in corrcoef) to 0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cA(find(isnan(cA))) = 0;
cB(find(isnan(cB))) = 0;
cC(find(isnan(cC))) = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Only consider non-Infs
% -- throw away stuff on same tetrode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f1 = find(isinf(cA)==0);
cA = cA(f1);
cB = cB(f1);
cC = cC(f1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute the correlations of the correlations for each interval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
n_bootstraps = 100;
if bootstrap
    r = bootstrp(n_bootstraps,'corrcoef',cA,cB);
    rB_A = mean(r(:,2));
    stdrB_A = std(r(:,2));
else 
    r = corrcoef(cA,cB);
    rB_A = r(1,2);
end


if bootstrap
    r = bootstrp(n_bootstraps,'corrcoef',cC,cB);
    rB_C  = mean(r(:,2));
    stdrB_C  = std(r(:,2));
    r = bootstrp(n_bootstraps,'corrcoef',cA,cC);
    rA_C  = mean(r(:,2));
    stdrA_C  = std(r(:,2));
else
    rB_C = diag(corrcoef(cC,cB),1);
    rA_C = diag(corrcoef(cA,cC),1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute the corrcoef (r) for m,s2|s1 for each interval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
r = zeros(1,2);
r(1) = rB_A; % First element is not the partial. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The partial corrcoef calculation...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
a = sqrt((1 - rB_A.^2).* (1 - rA_C.^2));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% partial correlation coeff (r) of B_C|A, r^2 is the explained variance.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
r(2) = (rB_C - rB_A.*rA_C) ./ a;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Provide some extra stats if desired
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargout > 1
    mean_r = mean([cA(:) cB(:) cC(:)]);
    std_r = std([cA(:) cB(:) cC(:)]);
end

function S = Shifted(AA,nShifts)
% Time shift A by N Shifts
colsAA = Cols(AA);
rowsAA = Rows(AA);
% Inefficient way
%S = AA;
%for ii = 1:(nShifts)
%    S = [S , [ones(ii,colsAA)*0; AA(1:(rowsAA-ii),:)]];
%end

% Efficient way
S = zeros(rowsAA,colsAA*nShifts);
S(:, 1:colsAA) = AA;
for ii = 1:nShifts
    S(:,(colsAA*ii+1):(colsAA*(ii+1))) = [ones(ii,colsAA)*0; AA(1:(rowsAA-ii),:)];
end

return