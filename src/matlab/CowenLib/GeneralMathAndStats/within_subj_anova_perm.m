function [p, CIs95, CISD] = within_subj_anova_perm(M,nPerm)
% WORK IN PROGRESS!!!
if nargin < 2
    nPerm = 500;
end

nCols = Cols(M);
MN = zeros(nPerm,nCols);
SD = zeros(nPerm,nCols);
for iP = 1:nPerm
    for iR = 1:Rows(M)
        B(iR,:) = M(iR,randperm(nCols));
    end
    MN(iP,:) = nanmean(B);
    SD(iP,:) = std(B);
end
plot(nanmean(MN))
hold on
plot(nanmean(MN) + std(MN)*1.96)
plot(nanmean(MN) - std(MN)*1.96)
plot(nanmean(M),'k');
plot(nanmean(M) + Sem(M),'r');
plot(nanmean(M) - Sem(M),'r');

