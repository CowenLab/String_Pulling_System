function saen = SampEn_cowen( dim, r, data, tau )
% SAMPEN Sample Entropy
%   calculates the sample entropy of a given time series data

%   SampEn is conceptually similar to approximate entropy (ApEn), but has
%   following differences:
%       1) SampEn does not count self-matching. The possible trouble of
%       having log(0) is avoided by taking logarithm at the latest step.
%       2) SampEn does not depend on the datasize as much as ApEn does. The
%       comparison is shown in the graph that is uploaded.

%   dim     : embedded dimension (seems to be 2 sometimes - see
%             https://www.physiology.org/doi/full/10.1152/ajpheart.2000.278.6.h2039)
%   r       : tolerance (typically 0.2 * std)
%   data    : time-series data
%   tau     : delay time for downsampling (user can omit this, in which case
%             the default value is 1)
%
%---------------------------------------------------------------------
% coded by Kijoon Lee,  kjlee@ntu.edu.sg
% Mar 21, 2012
% Cowen was just tweaking things to see if he could speed things up - but
% no luck so far - gpuArray did not help - made things worse.
%---------------------------------------------------------------------

if nargin < 4, tau = 1; end
if tau > 1, data = downsample(data, tau); end

N = length(data);
correl = zeros(1,2);
dataMat = zeros(dim+1,N-dim);
for i = 1:dim+1
    dataMat(i,:) = data(i:N-dim+i-1);
end

for m = dim:dim+1
    count = zeros(1,N-dim);
    tempMat = dataMat(1:m,:);
%      tic
%      tempMat = gpuArray(tempMat); % this quadruples the time so forget it.
    
    parfor i = 1:N-m % parfor can triple the speed.
        % calculate Chebyshev distance, excluding self-matching case
        dist = max(abs(tempMat(:,i+1:N-dim) - repmat(tempMat(:,i),1,N-dim-i)));
        
        % calculate Heaviside function of the distance
        % User can change it to any other function
        % for modified sample entropy (mSampEn) calculation
%          D = gather(dist < r);
         D = (dist < r);
        
        count(i) = sum(D)/(N-dim);
    end
%      toc
%     
    correl(m-dim+1) = sum(count)/(N-dim);
end

saen = log(correl(1)/correl(2));
end

