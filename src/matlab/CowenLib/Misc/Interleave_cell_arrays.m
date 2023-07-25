function C = Interleave_cell_arrays(varargin)
% Interleaves the values of n cell arrays. (i.e. 1 1 2 2 3 3 4 4 5 5
% ....)
%
% INPUT: A variable number of cell arrays of equal length
%
% OUTPUT: A single interleaved cell array
%
%

% cowen Wed Jul 14 16:20:37 1999

L = length(varargin)
cnt = 1;
for ii = 1:L:length(varargin{1})*L
  for jj = 0:L-1
    C{ii+jj} = varargin{jj+1}{cnt};
  end
  cnt = cnt + 1;
end
