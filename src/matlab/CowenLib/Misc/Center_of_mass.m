function [o, ix]= Center_of_mass(C,x)
%function [o ix] = Center_of_mass(C,x);
% Center of mass in x - where x is the x axis and C are the weights for
% each element of x.
% Assumes C is either a row vector or a matrix where each row is a vector 
% to compute the center of mass upon.
% o = center of mass
% ix = the index in x of the closest elemet to the center of mass.
%
% Call as such: [x] = Center_of_mass([0 0 2 4 0 0 1 ],1:7)
%
% Cowen 2018
%
%
if size(C,2) == 1
    % User passed in a column vector.
    C = C';
end
if any(C<0)
    error('Negative values in C - must be all > 0')
end
if Rows(C)>1
    s = sum(C.*repmat(x(:)',Rows(C),1),2);
    o = s./(sum(C,2)+eps);
    if nargout > 1
        ix = zeros(Rows(C),1);
        for iR = 1:Rows(C)
            ix(iR) = Closest(x,o(iR));
        end
    end
    BIX = sum(C,2) == 0;
    o(BIX)=nan;
else
    if nargin == 1
        x = 1:length(C);
    end
    o = sum(C.*x)./(sum(C)+eps);
    ix = Closest(x,o);
end



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