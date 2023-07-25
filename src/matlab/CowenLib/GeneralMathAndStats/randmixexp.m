function R = randmixexp(a,b1,b2,n)
%
% random numbers taken from mixed exponential distribution
% pdf = a*(1/b1)*exp(-x/b1) + (1-a)*(1/b2)*exp(-x/b2)
% cdf = a*(1-exp(-x/b1)) + (1-a)*(1-exp(-x/b2))
%
% R = randmixexp(a,b1,b2,n)
if nargin < 4;  n=1;   end
r = rand(1,n);
ind = r<a;
nind = ~ind;
r = rand(1,n);
R(ind) = -log(r(ind))*b1;
R(nind) = -log(r(nind))*b2
 % David Goodmanson