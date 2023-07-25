function stats = SPEC_bootstrap_PSD_comparison(Mca, nReps)
% INPUT a cell array of 2 elements where each element is a group. Within
% each cell array is an nsample by nfrequency PSD for each of the 2 groups.
% Perform nRep t-tests and compue the distribution of true positives from
% the single comparison and the shuffled comparison.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 0
    Mca = {randn(20,100) randn(30,100)};
    Mca{1}(:,4) = Mca{1}(:,4) + 1;
    Mca{1}(:,10:20) = Mca{1}(:,10:20)  + .5;
    nReps = 2000;
end
%%
[~,stats.original_p] = ttest2(Mca{1}, Mca{2});
stats.all_boot_p = nan(nReps,Cols(Mca{1}));

n(1:2) = [Rows(Mca{1}) Rows(Mca{2})];
ALM = [Mca{1}; Mca{2}];
alln = Rows(ALM);
% minsamp = min(n);
for iRep = 1:nReps
    rp = randperm(alln);
    [~,stats.all_boot_p(iRep,:)] = ttest2(ALM(rp(1:(n(1)-1)),:), ALM(rp(n(1):end),:));
end
stats.perm_p = sum(stats.all_boot_p < stats.original_p)/nReps;

if nargout == 0
    figure;
    subplot(2,1,1)
    histogram(stats.all_boot_p(:,1))
    subplot(2,1,2)
    bar([stats.perm_p; stats.original_p]')
end