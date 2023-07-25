function stats = Permutation_test(Mca, nReps)
% INPUT a cell array of 2 elements where each element is a group. Within
% each cell array is an nsample by nfrequency PSD for each of the 2 groups.
% find the MEAN difference. compare the distribution of these differences
% to the original differences. 
% 
% Other than sampling without replacement, how is this different than
% bootstrapping?
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 0
    Mca = {randn(20,100) randn(30,100)};
%     Mca = {randg(1.1,20,100) randg(1.1,30,100)};
    
    Mca{1}(:,4) = Mca{1}(:,4) + 1;
    Mca{1}(:,10:20) = Mca{1}(:,10:20)  + .5;
    nReps = 2000;
end
%%
[~,stats.original_p] = ttest2(Mca{1}, Mca{2});
stats.orig_diff = nanmean(Mca{1}) - nanmean(Mca{2});

n(1:2) = [Rows(Mca{1}) Rows(Mca{2})];
ALM = [Mca{1}; Mca{2}];
alln = Rows(ALM);
stats.all_perm_p = nan(nReps,Cols(Mca{1}));
D = nan(nReps,Cols(Mca{1}));

for iRep = 1:nReps
    rp = randperm(alln);
    D(iRep,:) = nanmean(ALM(rp(1:(n(1)-1)),:)) - nanmean(ALM(rp(n(1):end),:));
    [~,stats.all_perm_p(iRep,:)] = ttest2(ALM(rp(1:(n(1)-1)),:), ALM(rp(n(1):end),:));
end
%
for iCol = 1:Cols(D)
%     vs = sort(D(:,iCol));
    IX = sum(vs >= stats.orig_diff(iCol));
    stats.perm_pU (iCol) = sum(IX)/nReps;
    IX = sum(vs <= stats.orig_diff(iCol));
    stats.perm_pL (iCol) = sum(IX)/nReps;
%     if stats.perm_p(iCol) > 0.5
%         stats.perm_p(iCol) = 1-stats.perm_p (iCol);
%     end
end
% All of this would be simpler if I just took the abs value to copute the 2
% sided distribution.
stats.perm_p = min( [stats.perm_pL; stats.perm_pU])*2;
stats.test_perm_p = sum(stats.all_perm_p < stats.original_p)/nReps;

if nargout == 0
    figure;
    subplot(2,1,1)
    histogram(stats.all_perm_p(:,1))
    subplot(2,1,2)
    bar([stats.perm_p; stats.test_perm_p; stats.original_p]')
    legend('perm','permtte','orig p')
    axis tight
end