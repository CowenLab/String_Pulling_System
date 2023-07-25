function [E, TE, nCE, nFP, nFN, nE, trials_per_class] = Error_calculation(actual_classes, desired_classes, classes);
% INPUT 
%       actual_classes  = trial by class matrix of the actual output classes from some discriminator
%       desired_classes = the dexire outpud (trial by class of 0s and 1s)
%       classes         = a vector of all of the possible classes. For instance, if the 
%                         classes range from 1 to 4, then the vector 1:4 should be passed in.
%
% OUTPUT
%       E = actual_classes - desired_classes
%       TE = total error (percentage, over all categories)
%       CE = number of errors for each category
%       FP = number of false positive errors per category
%       FN = number of false negative errors per category
%

% cowen

% To make things easier, convert the actual and desired classes(vectors if class ids)
% to trial by class matrices where a 1 denotes a selection and a 0 not.
if length(actual_classes) ~= length(desired_classes)
  error('actual and desired classes must have same length')
end
classes = sort(classes);
n_trials = length(actual_classes);
n_classes = length(classes);

A = zeros(n_trials,n_classes);
D = zeros(n_trials,n_classes);

% set the chosen classes to 1. (a trial by class matrix)
A(sub2ind([n_trials,n_classes],[1:n_trials]',actual_classes(:))) = 1;
D(sub2ind([n_trials,n_classes],[1:n_trials]',desired_classes(:))) = 1;

trials_per_class = sum(D);

E = A-D;
% The total errer percent is just the number you got wrong/n_trials
nE = sum(actual_classes ~= desired_classes); % number of errors
TE = nE/n_trials*100;
% False positives
nFP = sum(E==1);
% False positives
nFN = sum(E==-1);
% Total errors per category
nCE = (nFP+nFN);

