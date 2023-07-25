function [...
    actual_classes,...
    distances,...
    method_name,...
    errors, ...
    total_error_perc, ...
    n_errors_per_cat, ...
    n_false_pos_per_cat, ...
    n_false_neg_per_cat, ...
    n_errors, ...
    trials_per_cat ] = Multi_discriminators(test, test_classes, train, train_classes, classes, method)
% INPUT 
%      test     - a trial by category(group) matrix to apply the discriminator on.
%      train    - a trial by category(group) matrix of data to train the discriminator.
%      train_classes - the categories for each row of the train data.
%      test_classes - trial by category matrix of errors. a zero indicates no error. a
%                     -1 indicates this category should have been chosen but wasn't. A +1
%                     indicates that this category was chosen but should not have been. The percent
%                     correct for each category = sum(test_classes == 0)/Rows(test_claases).
%                     the total percent correct = sum(test_classes(:) == 0)
%out_classes, distances, errors, methods
% OUTPUT
%      out_classes - a cell array of output classes for each discriminator.
%      distances   - a cell array of the distance for each category (class/group)
%      errors      - a trial by
%      method      - a text string that identifies the discriminator for each 
%                    element in the cell arrays.
% 

% cowen

classes = sort(classes);
n_classes = length(classes);
switch method
case 1
  method_name = 'Bayes, Poisson, non-tess';
  [actual_classes, distances] = Bayes_discriminator(test, train, train_classes,[],'poisson');
 
case 2
  method_name = 'Bayes, Gaussian, non-tess';
  [actual_classes, distances] = Bayes_discriminator(test, train, train_classes);
  
otherwise
  error('no such method')
end
if nargout > 3
  [   errors, ...
      total_error_perc, ...
      n_errors_per_cat, ...
      n_false_pos_per_cat, ...
      n_false_neg_per_cat, ...
      n_errors, ...
      trials_per_cat ] =  Error_calculation(actual_classes, test_classes,1:n_classes);
  end
  