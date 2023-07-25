% Artificial Data For Testing Change Point Analysis
%%
n_datasets = 20;
n_points = 400;
buffer_pts_on_ends = 50;
M = zeros(n_datasets,n_points)*nan;
change_points_and_means = zeros(n_datasets,3)*nan;

difficulty = 2.2; % .2 is REALLY easy, 1 is OK, 10 is REALLY HARD.
difficulty = 0.2; % .2 is REALLY easy, 1 is OK, 10 is REALLY HARD.

for ii = 1:n_datasets
    real_change_pt = round(rand(1,1)*(n_points-buffer_pts_on_ends));
    real_change_pt = real_change_pt + buffer_pts_on_ends/2;
    mean_1 = 1 + randn(1,1)/difficulty;
    mean_2 = 1 + randn(1,1)/difficulty;
    change_points_and_means(ii,:) = [real_change_pt mean_1 mean_2];
    
    M(ii,1:(real_change_pt-1)) = [mean_1 + randn(1,(real_change_pt-1))];
    npts = n_points - real_change_pt + 1;
    M(ii,real_change_pt:end) =  [mean_2 + randn(1,npts)];
end
%%
% figure
% plot_LFP(standardize_range( M'))

figure
imagesc(M)
hold on
for ii = 1:n_datasets
    plot(change_points_and_means(ii,1),ii,'r*')
end
title('Change point validation data')

%%

[bps conf_p] = Breakpoint_analysis_R(M);
%% Compare the results
[change_points_and_means(:,1) bps conf_p]
err = mean((change_points_and_means(:,1)-bps).^2);

figure 
plot(1:n_datasets, change_points_and_means(:,1), 1:n_datasets, bps)
legend('actual','predicted')
title(['Difficulty: ' num2str(difficulty) ' Error: ' num2str(err)])
a = axis;
IX = conf_p < 0.01;
x = 1:n_datasets;
% put a star by significant differences.
hold on
plot(x(IX),ones(sum(IX),1)*a(4),'r*')

