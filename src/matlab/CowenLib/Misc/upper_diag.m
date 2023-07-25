function [R,ud,ix,UD] = upper_diag(R)
% returns the upper diagonal as either a matrix with nans for all non upper
% diagonal and/or as a vector of just the upper diagonal.
%
% Cowen 2020
UD = triu(ones(size(R)),1)>0;
R(~UD)= nan;
ud = R(UD);
ix = find(UD);
