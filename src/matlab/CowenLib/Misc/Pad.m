function [P,GIX] = Pad(V,dims,padval)
%function P = Pad(V,dims,padval)
% Add some padding to a VECTOR. put padval at the end of the vector or cut off
% the vector so it is of length dims.
%
% INPUT: V the vector to pad
%        dims: the desired lenght of the vector
%        padval: the value to assign to the padded values.
% 
% OUTPUT: the padded vector.

l = length(V);
if l > dims
  disp('WARNING: the vector is longer than the dim')
end

if nargin == 2
  padval = 0;
end

if size(V,1) > 1
  V = [V;ones(dims,1)*padval];
else
  V = [V,ones(1,dims)*padval];
end

P = V(1:dims);
