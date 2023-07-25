function [S, bb] = Hsmooth(H)
%
%  [S, bb] = Hsmooth(H)
%
% smoothes a 2D histogram H (= 2D array)
% with a 6-th order double low pass firls bb (linear phase least-square FIR filter)
% by lipa
% cowen: tried the alternatvei conv2.

% create filter
%b = firls(6, [0 .5 .5 1], [1 .5 .5 0]);  from sig proc toolbox. No need to
%use if you know b.

b = [ 0.0225158185871862    -2.80653567739121e-018  0.202642367284676  0.5         0.202642367284676    -2.80653567739121e-018  0.0225158185871862];
%b = [0 .1 .3 .8 1.5 .8 .3 .1 0]; % A wider convolution -- more fuzzy.
%bb = kron(b',b);    % 2D filter = tensor product of 1D filters

%S = filter2(bb,H);  % first pass (introduces a linear phase shift)
%S = filter2(bb',S);  % second pass (compensates phase shift)

% Alternative is to use a convolution with a gaussian. (see conv2)
S = conv2(b,b,H,'same');