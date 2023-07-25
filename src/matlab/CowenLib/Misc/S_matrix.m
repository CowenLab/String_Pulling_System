function cc = S_matrix(Q1, Q2, class, method)
% $Id: S_matrix.m,v 1.0 2000-10-19 12:33:40-07 nsma Exp nsma $ 
%function cc = S_matrix(Q1, Q2, class)
%  Catenates the two input matrices together and then runs corrceof on them.
%  The class variable is optional.
%  Passing class = 'submatrix2' will produce the non-diagonal
%  sub-matrix of the S matrix, submatrix 2 will cut out the inner
%  submatrix. See below.
%
% The following shows which submatrices will be cut.
% |1|2|
% -----
% |2|3|
% 
% method indicates the comparison method. corroef is the default.
%
% cowen Sat Oct 17 14:53:09 1998


if nargin <= 2
  class = 'bigS';
elseif nargin <= 3
  method = 'corrcoef';
end

switch method
  case 'corrcoef'; % Default
    cc = corrcoef( [Q1 Q2]);
  case 'dotprod' 
    % Use the matrix dot product(the angle betweek the column vectors)
    disp('using dotprod');
    N = Normalize([Q1 Q2]);
    cc = N' * N;
  otherwise
    error('Improper method passed to S_matrix.');
end


switch class
  case 'bigS'
    % Return the entire S matrix.
  case 'submatrix1'
    [rQ1 cQ1] = size(Q1);
    cc = cc(1:cQ1,1:cQ1);
  case 'submatrix2'
    [rQ1 cQ1] = size(Q1);
    cc = cc(1:cQ1,cQ1+1:end);
  case 'submatrix3' 
    [rQ1 cQ1] = size(Q1);
    cc = cc(cQ1+1:end,cQ1+1:end);
  otherwise
    error('Invalid class option in S matrix.');
end

