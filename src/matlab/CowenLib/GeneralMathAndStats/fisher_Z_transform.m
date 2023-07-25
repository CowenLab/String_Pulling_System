function FZ = fisher_Z_transform(R)
%function fz = fisher_Z_score(R)
% INPUT
%  A matrix of r values 
% OUTPUT:
%  fisher_z_transform.
%
% A correlation coefficient can be transformed into a z-score for purposes
% of hypothesis testing. This is done by dividing the correlation plus 1, 
% by the same correlation minus 1; then take the natural log of the result;
% then divide that result by 2. The end result is Fisher's z-score
% transformation of Pearson's r. Fisher's transformation reduces skew and 
% makes the sampling distribution more normal as sample size increases. 
%
% The function looks like a tangent or a 90degree rotated sigmoid -
% accentuates the extreme values to flatten the distribution. 
% NOTE: Jean-marc does something like this with his distribution.
%https://en.wikipedia.org/wiki/Fisher_transformation
% cowen 2005 - 2016 updated to tanh.
% FZ =real( log((R+1)./(R-1))./2);
FZ = real(atanh(R));