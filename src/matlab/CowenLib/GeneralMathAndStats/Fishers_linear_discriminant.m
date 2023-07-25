function [features, w] = Fishers_linear_discriminant(train_features, train_targets)
%Reshape the data points using the Fisher's linear discriminant
%Inputs:
%	train_features	- Input features
%	train_targets	- Input targets
%
%Outputs
%	features			- New features
%   w					- Weights vector
% from classification_toolbox. (not mine -- cowen I cleaned it up thouhg-- it had superfluous vbls and erroneous statements.)

train_one  = find(train_targets == 1);
train_zero = find(train_targets == 0);

s0			  = cov(train_features(:,train_zero)');
m0			  = mean(train_features(:,train_zero)');
s1			  = cov(train_features(:,train_one)');
m1			  = mean(train_features(:,train_one)');

sw			  = s0 + s1;
w			  = inv(sw)*(m0-m1)';
features      = w'*train_features;
