function [isall ix]= intersect_n(varargin)
%function [isall ix]= intersect_n(varargin)
% Intersection between many sets - put each set as a separate argin
% isall = common intersection values
% ix = cell array of indices into each varargin of these common values.
% cowen(2006)
prev = [];
for ii = 1:(nargin-1)
   is = intersect(varargin{ii},varargin{ii+1});
   if ii > 1
       isall = intersect(is,prev);
       prev =  isall;
   else
       prev = is;
   end
end
% Return the indices in each varargin with these values.
for ii = 1:nargin
    [tmp,ix{ii}] = intersect(varargin{ii},isall);
end
