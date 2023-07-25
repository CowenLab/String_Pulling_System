function c = bayes_partition_class_wrapper(dtest,dtrain,gtrain)
% Wrapper for bayes partition code.
%  NOTE: TOOOOO SLOW TO BE PRACTICAL.
data = [gtrain(:) dtrain];
test = [ones(size(dtest,1),1) dtest]; % ignore the test data.
test_set_predictions = bayes_partition_class(data,test);

[mx,c] = max(test_set_predictions.pred_store);