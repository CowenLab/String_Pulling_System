function d = Density(M)
% Given a matrix, measure the density of each column in the matrix
% UPDATE - See Spareseness_measures.m
% Density is sparsity. I just feel density is more intuitive becuase the larger the number,
% the more dense(less sparse) the representation. 
%                     d = (mean(M).^2)./mean(M.^2);
% INPUT:  Matrix
%
% OUTPUT: Vector of density measures from 0 to 1. NaNs are made into
% zeros.
%(Rolls and Tovee 1995)
%function d = Density(M)
%

% cowen Mon Mar 29 10:04:26 1999
%
%warning off
if min(M(:)) < 0
    error('CV and classic sparsity measures are not appropriate for matrices with negative numbers.')
    return
end
    
d = (mean(M).^2)./mean(M.^2);
d(isnan(d)) = 0;
%warning on