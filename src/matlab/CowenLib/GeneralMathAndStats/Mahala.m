%
% Calculate Mahalanobis Distance
% ++++++++++++++++++++++++++++++
%
% Copyright (C) D. Redpath 19/05/03
%
% Version 1.0
%
% Oceans Systems Group                          
% Heriot-Watt University                      
% Edinburgh, UK.
%
%
% USAGE: D = Mahala(X,Y,subset) 
%
%   X: Feature Vectors, col of feats, rows of samples
%
%   Y: Class label coloumn vector, two classes only !
%
%   subset: Subset of features of origi3nal X
%
% Output
%
%   D: Mahal Distance
%
% EG:  D = Mahala(X,Y,subset)
% cowen - removed the subset option.
function D = Mahala(class1,class2)
if( size(class1,1)<size(class1,2) | size(class2,1)<size(class1,2) )
   error('Must have more samples than features in min class!\n\n');
end
nSamples = size(class1,1) + size(class2,1);
cov1=cov(class1);
cov2=cov(class2);
% Mahalanobis assumes equal covariance matricies ! 
% Have one for each class so use within class scatter matrix to estimate covariance.
covm=(size(class1,1)/nSamples)*cov1 + (size(class2,1)/nSamples)*cov2;
% Distance
D = (mean(class2) - mean(class1)) * inv(covm) * (mean(class2) - mean(class1))';
