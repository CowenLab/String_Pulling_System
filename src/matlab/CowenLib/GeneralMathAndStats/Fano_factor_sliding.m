function FF = Fano_factor_sliding(M,window_size_bins)
% function ff = Fano(V)
%
% Compute the fano factor using a sliding window. Assumes matrix M is a
% column mantrix with independent columns. The window is slide DOWN the
% columns (e.g. incremented by 1 row each time)
% Each row is a point in time, each column is a TRIAL

% Cowen 
nTrials = size(M,2);
nTimes = size(M,1);
v = zeros(nTimes-window_size_bins,nTrials)*nan;
m = zeros(nTimes-window_size_bins,nTrials)*nan;
% mid = floor(window_size_bins/2);
for iTime = 1:(nTimes-window_size_bins)
    v(iTime,:) = nanvar(M(iTime:(iTime-1+window_size_bins),:));
    m(iTime,:) = nanmean(M(iTime:(iTime-1+window_size_bins),:));
end
FF = v./(m+eps);


%
% Compute the fano factor of an input vector n samples long.
%
% Fano factor is dangerous for the following reason... Fano_Factor is a BAD
% measure when you use it as a measure of a MEAN response – it will be terribly 
% sensitive to sample size BECAUSE with lower sample sizes, 
% the variance will be MUCH higher from repeated sampling of the mean. 
% For example, say you have some hidden process with a real mean of 5Hz. 
% You then go ahead and are allowed, each day, to take between 1 and 20 
% samples in order to estimate the mean. If you look at the variance between 
% estimates on the days when you took 1 sample, the variance will be REALLY 
% high relative to the days which you took 20 samples – as these days will
% almost invariably have a mean of 5Hz. Thus, even though the mean is the 
% same, the var will be higher and the fano will be higher.
