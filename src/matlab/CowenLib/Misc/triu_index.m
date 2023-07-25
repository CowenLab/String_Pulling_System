function [in_ix,M,out_ix] = triu_index(M,o)
% Return the indices for the triu - also return the values in c.
%  o = how many diagonals above the central diagonal.
%
%
Z = triu(ones(size(M)),o);
in_ix = find(Z==1);
out_ix = find(Z==0);
M(out_ix) = nan;
