function [STATS] = bootstrap_hypothesis_circular_phase_lag_test(X,Y,lag,nboot)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% X and Y are the 2 separate vectors of the 2 groups. (so n_samples_1 =
% length(D), n_samples_2 = length(G);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

STATS.pval_thresh = 0.01;

if nargin < 3
    lag = 0;
end

if nargin < 4
    nboot = 5000;
end

if length(X) < 20;
    disp('Sample size tooo low')
    p = nan;
    return
end

% get rid of nans
GIX = ~isnan(X) & ~isnan(Y);
X  = X(GIX); Y = Y(GIX);

n1 = length(X);
n2 = length(Y);
lags = circ_dist(X,Y);
STATS.true_mean_lag = circ_mean(lags); % big question: is this different than the lag?
% Do classic circular statistics.
STATS.hmtest =  circ_mtest(lags',lag,STATS.pval_thresh);

low = ang2rad(-0.5); 
high = ang2rad(0.5); 
n_true_zero_lags = sum(lags>=low & lags<=high);
prop_true_zero_lags = n_true_zero_lags/length(X);
% perform the sub-sampling and get the sampling distribution.
m = zeros(nboot,2);
pop = randperm(length(X));
pop(pop<10) = [];
boot_mean_lag = zeros(nboot,1);
prop_nzs = zeros(nboot,1);
nzs = zeros(nboot,1);
N = length(pop);

for iBoot = 1:nboot
    Xs = circshift(X,[randsample(pop,1) 0]);
    lags_boot = circ_dist(Xs,Y);
    nzs(iBoot)  = sum(lags_boot>=low & lags_boot<=high);
    prop_nzs(iBoot)  = nzs(iBoot) / N;

    boot_mean_lag(iBoot) = circ_mean(lags_boot);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
srt_prob = sort(prop_nzs);
ix = find(srt_prob >= prop_true_zero_lags,1,'first');
p = ix/length(srt_prob);
if p > 0.5
    p = 1-p;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
STATS.p_boot = p;
[STATS.boot_lowup_alphapt05] = prctile(srt_prob,[2.5 97.5]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargout == 0
    figure
    histogram(prop_nzs)
    figure
    histogram(boot_mean_lag,-pi:ang2rad(4):pi);
end