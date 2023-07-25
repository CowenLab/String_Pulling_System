function [class, perf_by_category_and_rnd, performance, CONFUSION] = leave_one_out_classify(data, group, type, prior, option, option_parameters)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function [class, err, T_h, T_p, rand_err] = leave_one_out_classify(data, group, type, prior, option, option_parameters)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A wrapper for the matlab classify function. This function performs leave-one-out classification
% on the data. It breaks the data into training (all but one) and test (one sample). It repeats this
% and generates statistics on the discriminablility of the 2 groups. Significance is performed by 
% shuffling membership between groups.
%
% INPUT: data = nsamples by ndimensions; group, a vector of group membership IDs.
% 
%        option = 'plot' plot summary performance comparing L1O results with the randomly mixed version 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% to test, do the following...
%[class, perf_by_category_and_rnd, performance] = leave_one_out_classify([], [], [], [], {'use_testdata'},{[]})
%
%  The type and prior parameters are only applicable if you are using matlab 6.5 or above.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen(2004)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin <5
    option = [];
end

if ismember('use_testdata',option)
    % Test with test data. User can just pass in empty strings or whatever for the other parameters
    nSamples = 40;
    data = rand(nSamples,10);
    group = ones(nSamples,1);
    idx = round(nSamples/2);
    group(idx:end) = 2;
    data(idx:end,4) = rand(length(data(idx:end,4)),1)*1.7;
    data(1:(idx-1),3) = rand(length(data(1:idx-1,3)),1)*.87;
    figure
    imagesc(data);drawnow
end
    
group_ids = unique(group);
nGroups = length(group_ids);
nSamples = Rows(data);
class = zeros(nSamples,1)*nan;
err   = zeros(nSamples,1)*nan;
rand_class = zeros(nSamples,1)*nan;
rand_err   = zeros(nSamples,1)*nan;
% Randomize the group assignements for the test condition.
rand_group = group(randperm(nSamples));
for samp = 1:nSamples
    test_idx = samp;
    train_idx = setdiff(1:nSamples,test_idx);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % I stopped using the error output of classify as it wasn't meaningful -- it was
    % never at chance, even for random data and significant difference were
    % found for randomized data. It makes me very suspicious.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [class(samp)] = classify(data(test_idx,:),data(train_idx,:),group(train_idx),type);
    [rand_class(samp)] = classify(data(test_idx,:),data(train_idx,:),rand_group(train_idx),type);
    if mod(samp,50)==0
        fprintf('>')
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Error - classification errors
%  and the CONFUSTION matrix.
% looks like this...
%      Predicted Class  1 2
%  Hypothesized  Class 1
%                      2 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CONFUSION = zeros(nGroups)*nan;
for ii = 1:nGroups
    for jj = 1:nGroups
        actual_class = group==group_ids(ii);
        desired_class = class==group_ids(jj);
        CONFUSION(ii,jj) = sum(actual_class.*desired_class);
    end
end
performance.CONFUSION = CONFUSION;
for ii = 1:nGroups
    in_group_idx = find(group==group_ids(ii));
    %out_group_idx = find(group~=group_ids(ii));
    total_in_group(ii) = sum(group==group_ids(ii));
    total_in_class(ii) = sum(class==group_ids(ii));
    true_positives(ii) = sum(group(in_group_idx)==class(in_group_idx));
    false_positives(ii) = total_in_group(ii) - true_positives(ii);
    %%%%%%%%%% Test for randomized data %%%%%%%%%%%%%%%
    in_group_idx = find(rand_group==group_ids(ii));
    rand_total_in_group(ii) = sum(rand_group==group_ids(ii));
    rand_total_in_class(ii) = sum(rand_class==group_ids(ii));
    rand_true_positives(ii) = sum(rand_group(in_group_idx)==class(in_group_idx));
    rand_false_positives(ii) = rand_total_in_group(ii) - rand_true_positives(ii);
    leg{ii} = ['cat ' num2str(ii)];
end
%%%%%%%%%%%%%%%%%%%%%%%%%
% True Vs. False Positives
%%%%%%%%%%%%%%%%%%%%%%%%%
perf_by_category_and_rnd = [true_positives./total_in_group rand_true_positives./rand_total_in_group ];
performance = mean(true_positives./total_in_group - 1/nGroups);
for ii = 1:length(option)
    switch option{ii}
        case 'plot'
            figure;
            subplot(2,1,1)
            bar([true_positives(:) false_positives(:) rand_true_positives(:) rand_false_positives(:)]')
            legend(leg,0)
            set(gca,'XTick',1:4)
            set(gca,'XTickLabel',{'true_positives', 'false_positives','rand_true_positives', 'rand_false_positives'});
            % Construct a confustion matrix.
            %CM = zeros(nGroups)*nan;
            subplot(2,1,2)
            bar([perf_by_category_and_rnd performance]*100)
            a = axis;a(4) = 100;axis(a);
            ylabel('%')
            title('Percent Correct By Category')
            set(gca,'XTick',1:5)
            set(gca,'XTickLabel',{'original 1', '2','random 1', '2', 'mean orig above chance'});
        otherwise
    end
end