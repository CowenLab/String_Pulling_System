function [ix, minv] = Closest(V, a)
% Returns the index or indices in V that point to valuse in V that are
% closest to a
%
% INPUT:  V Vector or matrix of values
%         a The value you want to compare to V
%
% OUTPUT: indices in V that are closest to a
%
%function ix = Closest(V, a)
% cowen Fri Apr 16 18:07:26 1999 0 
% cowen 2012 - allows you to use a vector in a.
minv = zeros(size(a));
ix = zeros(size(a));
for ii = 1:length(a)
    [m,i] = min(abs(V - a(ii)));
    minv(ii) = m(1);
    ix(ii) = i(1);
end