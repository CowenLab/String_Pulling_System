function [h]= Error_bars_grouped2(M, labels, varargin)
% M = each column is a group, each row is a datapoints..
% cowen - assumes just 2 groups for now.
error_type = 'SEM';
Extract_varargin;
switch error_type
    case 'SEM'
        err = Sem(M);
    otherwise
        error('wrong error type')
end

if 0 % for testing
    M = [316.45 292.14 319.96; 305.59 287.99 295.21]  % first 3 #s are pre-test, second 3 #s are post-test
    err = [13.12 5.67 12.36; 12.43 6.83 11.67]
    labels = {'a' 'n'};
end
% Plot
figure
hb = bar(M); % get the bar handles
hold on;
for k = 1:size(M,2)
    % get x positions per group
    xpos = hb(k).XData + hb(k).XOffset;
    % draw errorbar
    errorbar(xpos, M(:,k), err(:,k), 'LineStyle', 'none', ... 
        'Color', 'k', 'LineWidth', 1);
end

% Set Axis properties
set(gca,'xticklabel',labels);
