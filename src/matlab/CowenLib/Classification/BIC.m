function b = BIC(D,g)
%    Schwarz criterion for optimal number of cluster.
%    Bayesian Inference Criterion for stopping
%    BICs- BIC(t) = -2 * LL(t) + nu/2 log(n) where LL(t) is the maximum
%   value of the likelihood, nu is the number of parameters and n the
%   number of samples.
%    D = data  = nsamples x n Features
%    g = group membership
[nSamples, nFeatures] = size(D);
uG = unique(g);
nGroups = length(uG);

RSS = zeros(nSamples,1);
for ii = 1:length(uG)
    ix = find(g==uG(ii));
    RSS(ix) = [D(ix) - mean(D(ix))].^2;
end
MRSS = mean(RSS);
% From Wikipedia - this is wrong
b = nGroups*nFeatures*log(nSamples) + nSamples*log(MRSS);
%b = -2*maxLL+nFeatures/2*log(nSamples);