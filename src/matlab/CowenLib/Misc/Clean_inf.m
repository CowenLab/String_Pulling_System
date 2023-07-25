function A = Clean_inf(A, command)
%
% Pass in a vector and Clean_Inf will return a reduced vector
% that is devoid of all Infs.
% If a matrix is passed in, it will return a vector that contains all
% of the non-Inf numbers.
%
% INPUT: Vector or Matrix and command 'vectorout' or 'matrixout'
% OUTPUT: Vector or Matrix free of Infs
% 
%function A = Clean_inf(A, command)

%
% Cowen Thu Oct 15 16:55:33 1998

if nargin < 2
  error('specify vectorout or matrixout');
end

switch command
  case 'vectorout'
    % Output a vector free of Infs
    A(find(isinf(A))) = [];
  case 'matrixout'
    % Output a matrix free of Infs. Assumes the Infs are in rows and
    % cols.
    % Find the first column without a Inf
    [ii jj]= find(~isinf(A)); % Find a list of the non-Inf numbers
    [i infcols] = find(isinf(A(min(ii),:)));
    A(:, infcols) = [];
    [infrows j]= find(isinf(A(:,1)));
    A(infrows,:) = [];
    if sum(sum(isinf(A)))>0
      error('There are still some Infs left in the matrix.');
    end
  otherwise
    error('incorrect command sent to Clean_Inf');
end
