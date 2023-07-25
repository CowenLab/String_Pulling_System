    function cc = Coeff_compare(A, B, idx)
%function cc = Coeff_compare(A, B, idx)
% INPUT: A, B = the two matrices you wish to compare. Columns are variables, rows are samples.
%               idx = indices in the vbl x vbl matrix to eliminate from consideration
%
% OUTPUT:  A measure of similarity of the two matrices.
%
% NOTE: Nan's are converted to 0's. Nan's appear when columns in the input matrices are 0 or do 
%       not change. Also, the user must supply the idx. This avoids some overhead if 
%       this routine is called withing a loop.
%

% cowen

if nargin < 3
    error('You must provide indices of the legal elementes in the vbx x vbl matrix')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute the correlation coefficits for the variables (columns) in the matrices.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

warning off % This is really dangerous but it avoids some mess.
rA = full(corrcoef(A));
rB = full(corrcoef(B));
warning on
% 
rVecA = rA(idx);
rVecB = rB(idx);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set all Nans (where a vector had a length of 0) to 0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rVecA(isnan(rVecA)) = 0;
rVecB(isnan(rVecB)) = 0;

r = corrcoef(rVecA,rVecB);
cc = r(1,2);


