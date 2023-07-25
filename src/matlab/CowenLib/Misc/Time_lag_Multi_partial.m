function [r , mean_r, std_r ] = Time_lag_Multi_partial(A,B,C,interval_size,on_same_tet,rf_size)
% rf_size is in bins

if nargin <=5
  rf_size = 1;
end
if nargin <= 5 | rf_size ==1
  % No lag so just call multi partial
  [r , mean_r, std_r ]= Multi_partial(A,B,C,interval_size,on_same_tet)
else
  if 0
    A_idx = [];
    B_idx = [];
    C_idx = [];
    % Do some pre-processing
    ncells = Cols(A);
    for ii = 1:rf_size
      A_idx = [A_idx;[ii:(Rows(A)-rf_size+ii)]];
      B_idx = [B_idx;[ii:(Rows(B)-rf_size+ii)]];
      C_idx = [C_idx;[ii:(Rows(C)-rf_size+ii)]];
    end
    % time by cell+rfsize matrix
    newA = zeros(Rows(A)-rf_size+1,rf_size*ncells);
    newB = zeros(Rows(B)-rf_size+1,rf_size*ncells);
    newC = zeros(Rows(C)-rf_size+1,rf_size*ncells);
    %D = [];
    for cellid = 1:ncells
      vA = A(:,cellid); 
      vB = B(:,cellid); 
      vC = C(:,cellid); 
      % Use one cell.
      newA(:,(cellid*rf_size-rf_size+1):cellid*rf_size) = vA(A_idx)';
      newB(:,(cellid*rf_size-rf_size+1):cellid*rf_size) = vB(B_idx)';
      newC(:,(cellid*rf_size-rf_size+1):cellid*rf_size) = vC(C_idx)';
    end
  end
  newA = Tessel_matrix(A',1,rf_size,'by_col')';
  newB = Tessel_matrix(B',1,rf_size,'by_col')';
  newC = Tessel_matrix(C',1,rf_size,'by_col')';

  new_on_same_tet = repmat(on_same_tet(:)',rf_size,1);
  new_on_same_tet = new_on_same_tet(:);
  new_on_same_tet
  [r , mean_r, std_r ]= Multi_partial(newA,newB,newC,interval_size,new_on_same_tet);
end
