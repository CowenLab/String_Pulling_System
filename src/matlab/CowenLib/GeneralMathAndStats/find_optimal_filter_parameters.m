function [Error] = find_optimal_filter_parameters(test_data,signal,filter_type,params_to_explore);
% INPUT: sample data. the signal will be embedded into to the sample data
% and the mean error will be computed between the embedded signal and the
% data.
% 
% Error.test_data_E = MSE of the signal to the test data.
% Error.corrcoef = the vector of corrcoef between the filtered data and the
% signal
% Error.MSE = same as above, but the mean squared error.
%
%
test_data = test_data - mean(test_data);
n_trials = 100;
l = length(test_data);
siglen = length(signal);
sample_len = siglen*n_trials*max(params_to_explore);
if l<sample_len
    test_data = repmat(test_data(:)',1,ceil(sample_len/l));
end
for ii = 1:n_trials
    test_data(1:siglen) = test_data(1:s)+sigtest;
end
test_data = test_data - mean(test_data);

C = corrcoef(test_data,sigtest);
Error.test_data_corrcoef = C(2,1);

for ii = 1:length(params_to_explore)
    param = params_to_explore(ii);
    filter_window = feval(filter_type,param);
    z = zeros
    embedded_data = test_data(round(rand(1,1))*l - siglen:siglen)
    filtered_data = conv(test_data,filter_window);
    % Re-align the data so that it is centered in the middle of the filter.
    filtered_data = filtered_data(floor(param/2):end - ceil(param/2));
    C = corrcoef(filtered_data,sigtest);
    Error.corrcoef(ii) = C(2,1);
    figure
    plot(test_data,'b')
    hold on 
    plot(filtered_data,'r')
    title(['Param = ' num2str(param)])
    legend('original','filtered')
end