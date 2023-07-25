function T = Choose_winners(D,trial_ids)
% Sometimes a classification system has multiple trials per class (for instance, there
% may be multiple time bins during one trial as a rat ran towards a maze junction). Each 
% bin could be considererd on sample from one trial. The problem is to decide which 
% bin contains is the decisive bin-- the one that should be used to determine 
% the classification algorithm's choice for the output. This function does that by choosing
% the maximimum of the 
% 
% INPUT 
%    D - a sample by category matrix of distnaces to each category. 
%    trial_ids (optional)- a vector of unique id's that are associated with each element in D
%       if this is not specified, it is assumed that D is from a single trial.
% OUPUT
%  T - a vector the length of the number of trials that contains the winning class
%      as the index (column) in the input D matrix.

% cowen

if nargin == 1
  trial_ids = ones(size(D,1),1);
end

trials = unique(trial_ids);
n_trials=length(trials);
[n_samples, n_classes] = size(D);
T = zeros(n_trials,1);
for trl = 1:n_trials
  idx = find(trial_ids==trials(trl));
  X = D(idx,:);
  if size(X,1) == 1
    [d, T(trl)] = max(X);
  else
    [d, T(trl)] = max(max(X)); 
  end
end
