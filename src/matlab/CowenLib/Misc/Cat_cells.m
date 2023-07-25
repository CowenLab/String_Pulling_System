function C = Cat_cells(varargin)
%function C = Cat_cells(varargin)
% Concatenate cell arrays - any number of cell arrays
%
% INPUT: 
%      two or more cell arrays
% OUTPUT:
%      The concatenated cell array.
%

% cowen Thu Jun 24 12:53:18 1999, 2009
C = [];
s = size( varargin{1}{1});
if s(1) == 1
    dim = 2;
else
    dim = 1;
end

for iC = 1:length(varargin{1})
    C = cat(dim,C, varargin{1}{iC});
end




% 
% C = C1;
% for ii = (length(C1)+1):(length(C1) + length(C2) )
%   C{ii} = C2{counter};
%   counter = counter +1;
% end
% 
% if nargin == 3
%    C = Cat_cells(C, C3);
% end