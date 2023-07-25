function [predicted, activations, NET] = nn_marq_classify(test_set, train_set, train_group, test_group, option, option_parameters)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%
%
% Trains on a training set and tests on a test set. 
% activation is the activation of each hidden unit.
% Error is the error
%  THIS NETWORK WAS ORIGNALLY INTENDED FOR REAL VALUED FUNCTIONS.
% NET contains the network parameters such as the training rate, weights,
% number if iterations to criterion, etc...
%
% A wrapper for stuff from Magnus Norgaard, IAU/IMM, Tecnical University of
% Denmark
% Stephen cowen wrote the wrapper.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
if nargin < 4
    % Choose a random category for the test group since the user doesn't
    % care.
    test_group = ones(size(test_set,2),1);
end
train_set = train_set'; % Convert from the standard matlab convention of one sample per row to nnsid convention.
test_set = test_set'; % Convert from the standard matlab convention of one sample per row to nnsid convention.
test_group = test_group'; % Convert from the standard matlab convention of one sample per row to nnsid convention.
train_group = train_group'; % Convert from the standard matlab convention of one sample per row to nnsid convention.
rand('seed',0);
n_hidden = 4;
n_input = Cols(train_set);

classes = unique(train_group);
test_classes = unique(test_group);

n_classes = length(classes); % Have one output unit for each category.
n_test_classes = length(test_classes); % Have one output unit for each category.
n_samples = rows(train_set);
n_test_samples = rows(test_set);
desired_output = zeros(n_samples,n_classes);
actual_output = zeros(n_test_samples,n_classes);

for ii = 1:n_classes
    train_output(:,ii) = train_group == classes(ii); 
end

for ii = 1:n_test_classes
    test_output(:,ii) = test_group == test_classes(ii); 
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%W1         = rand(n_hidden,n_input);     % Weights to hidden layer 
%W2         = rand(n_output,n_hidden+1);  % Weights to output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
% The top row represents the structure of 
% the hidden layer. The bottom row represents
% the output structure.
n_dashes = max([n_hidden n_classes]);
NetDef = repmat('-',2,n_dashes);
NetDef(1,1:n_hidden) = 'H';
NetDef(2,1:n_classes) = 'L';
NET.trparms = settrain;      % Set training parameters to default values
NET.trparms= settrain(NET.trparms,'maxiter',200);
%%%%TRAIN%%%%%
%[NET.W1,NET.W2,NET.PI_vector,iter,lambda]=marq(NetDef,W1,W2,train_set,train_group,NET.trparms);
[NET.W1,NET.W2,NET.PI_vector,iter,lambda]=marq(NetDef,[],[],train_set,train_output',NET.trparms);
%%%%TEST%%%%%
[activations,NET.error,PI] = nneval(NetDef,NET.W1,NET.W2,test_set,test_output);
if Cols(activations) > 1
    [idx,predicted] = max(activations');
else
    predicted = zeros(1,Rows(test_group));
    predicted(find(activations <= .5)) = test_classes(1);
    predicted(find(activations > .5)) = test_classes(2);
end
