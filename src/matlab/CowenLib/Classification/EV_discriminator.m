function [class,r,r_matrix] = EV_discriminator(sample, training, group, on_same_tet,which_class_to_partial_out)
% INPUT
%      sample   - the data to classify (one row per sample, one column per variable (such as cell)).
%                 for reactivation studies, this would be the maze period time by cell matrix. All of the data
%                 in sample is treated as one trial and classified with the training data. 
%                 IMPORTANT: This means the ENTIRE sample set is assumed to belong to one category.
%      training - the data used to train the discriminator. (one row per sample, one column per variable (such as cell))
%                 for reactivation studies, this would be the time by cell matrices for pre and \
%                 post sleep. The group for each row (pre or post) is specified in group. If you 
%                 wished to break the post sleep period into sections (such as the first, second and
%                 third 10 minutes) you can specify each section as a separate group.
%      group    - the categories (or class) for each row in training. Also referred to class.
%      on_same_tet - these are the pair wise correlations to remove from the analysis-- for instance,
%                 if they were gathered from the same electrode.
%      which_class_to_partial_out - which class to partial out of the correlation analysis. This can only 
%                 be a scalar.
%
% OUTPUT
%      class    - the closest class in training to the sample data. 
%      r        - the Pearson's r statistic that measures the closeness of the correlation
%                 matrix in sample to the correlation matrices in the training categories.
%      r_matrix - the entire matrix of r values between all groups. The sample is in the last row and column \
%                 of the matrix. It's a corrcoef matrix so it's symmetric.

% cowen  


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do some superfluous error checking. (from classify.m)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%training = full(training); % Sometimes sparse matrices do wierd things.

group = group(:)';

if any(group - round(group)) | any(group < 1)
  error('The third input argument must be positive integers.');
end

[n_train_samples,n_vbls] = size(training);

if n_train_samples ~= length(group),
  error('The number of rows in the second and third input arguments must match.');
end

[n_samples,sc] = size(sample);
if sc ~= n_vbls
  error('The number of columns in the first and second input arguments must match.');
end

if nargin < 5
  which_class_to_partial = 0;
end
if nargin < 4
  on_same_tet = [];
  which_class_to_partial_out = 0;
end  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
group_ids = sort(unique(group));
n_groups = length(group_ids);

for ii = 1:n_groups
  priors(ii) = sum(group==group_ids(ii))/length(group);
end

if priors(1) ~= 1/n_groups
  disp('WARNING: If there are not equal numbers of items in each category, results will be based.')
  disp(['PRIORS: ' num2str(priors)])
end


if [1:n_groups] ~= group_ids
  error('groups must be integers starting at 1 and have no gaps')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The main code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for gg = 1:n_groups
  group_idx{gg} = find(group==group_ids(gg));
end

sample_group_idx = n_groups + 1;

% Create the correlation coefficient matrices for the training data.
upper_tri_idx = find(triu(ones(n_vbls,n_vbls))==1);
vC = zeros(length(upper_tri_idx),n_groups+1); % + 1 for the sample group
for grp = 1:n_groups %for the sample group
  %fprintf('.');
  % use full as sparse matrices can sometimes be flakey.
  % Avoid a divide by zero.
  warning off
  C = full(corrcoef(training(group_idx{grp},:)));
  warning on
  % Get rid of correlations on the same tetrodes.
  C(on_same_tet) = inf;
  % Take the upper diagonal (as C is symmetric) and convert it to a vector.
  % get rid of the infs as they are from cells on the same tetrode-- if you are
  % looking at cells that is.
  tmp = C(upper_tri_idx);
  vC(:,grp) = tmp(find(~isinf(tmp)));
end
% Get the C for the sample group.
warning off
C = full(corrcoef(sample));
warning on
% Get rid of correlations on the same tetrodes.
C(on_same_tet) = inf;
% Take the upper diagonal (as C is symmetric) and convert it to a vector.
% get rid of the infs as they are from cells on the same tetrode-- if you are
% looking at cells that is.
tmp = C(upper_tri_idx);
vC(:,sample_group_idx) = tmp(find(~isinf(tmp)));

% convert all Nans to 0. Why? Becasue nan probably means one of the cell
% pair never fired. It could have just fired once, providing a very very 
% low correlation-- so best to just assume the pair has a 0 correlation.
vC(find(isnan(vC))) = 0;

% Find the correlations between each training group and the sample
r_matrix = corrcoef(vC);

if which_class_to_partial_out == 0
  % If no partialling, just return the correlations of the sample to all of the classes
  % the sample correlation is 
  r = r_matrix(sample_group_idx,[1:(end-1)]);
else
  
  r(which_group_to_partial) = r_matrix(which_class_to_partial_out,sample_group_idx);
  groups = 1:n_groups;
  groups(which_class_to_partial_out) = [];
  
  for grp = groups
    a = sqrt((1 - r_matrix(sample_idx,which_class_to_partial_out).^2).* (1 - r_matrix(which_class_to_partial_out,grp).^2));
    % partial correlation coeff (r) of B_C|A r^2 is explained variance.
    r(grp) = (r_matrix(sample,grp) - r_matrix(sample,which_class_to_partial_out) .*r_matrix(which_class_to_partial_out,grp)) ./ a;
    %fprintf('%i ', grp);
  end					
end

[tmp, class] = max(r);
%class = class';

%for interval = 1:n_intervals
%  a = sqrt((1 - rB_A.^2).* (1 - rA_C(interval).^2));
% partial correlation coeff (r) of B_C|A r^2 is explained variance.
%  r(interval+1) = (rB_C(interval) - rB_A.*rA_C(interval)) ./ a;
%  fprintf('%i ', interval);
%end					



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

