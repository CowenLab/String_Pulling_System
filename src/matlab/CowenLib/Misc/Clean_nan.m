function A = Clean_nan(A, command)
%
% Pass in a ctsd or tsd and all Nan elements will be removed.
% Pass in a vector and Clean_Nan will return a reduced vector
% that is devoid of all NaNs.
% If a matrix is passed in, it will return a vector that contains all
% of the non-NaN numbers.
%
% INPUT: tsd, ctsd, Vector or Matrix and command 'vectorout' or 'matrixout'
% OUTPUT: tsd, ctsd, Vector or Matrix free of NaNs
%
%function A = Clean_nan(A, command)

% Cowen Sun Jun  6 16:56:21 1999 added tsd and ctsd 

if nargin < 2
  command = 'matrixout';
end

switch class(A)
  case 'tsd'
    a = Data(A);
    ts = Range(A,'ts');
    idx = find(isnan(a));
    a(idx) = [];
    ts(idx) = [];
    A = tsd(ts,a);
  case 'ctsd'
    a = Data(A);
    ts = Range(A,'ts');
    idx = find(isnan(a));
    a(idx) = [];
    ts(idx) = [];
    A = ctsd(ts,a);
  case 'double'
    switch command
      case 'vectorout'
	% Output a vector free of NaNs
	A(find(isnan(A))) = [];
      case 'matrixout'
	% Output a matrix free of NaNs. Assumes the NaNs are in rows and
	% cols.
	% Find the first column without a Nan
	[ii jj]= find(~isnan(A)); % Find a list of the non-NaN numbers
	[i nancols] = find(isnan(A(min(ii),:)));
	A(:, nancols) = [];
	[nanrows j]= find(isnan(A(:,1)));
	A(nanrows,:) = [];
	if sum(sum(isnan(A)))>0
	  error('There are still some NaNs left in the matrix.');
	end
      otherwise
	error('incorrect command sent to Clean_NaN');
    end
end