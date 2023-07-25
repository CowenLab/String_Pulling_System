function d = permutation_distribution(nperms,bootfun,V1,V2,val)
%function d = permutation_distribution(nperms,bootfun,V1,V2)
% permutes the values between V1 V2 without replacement (unlike bootstrap) to  
% generate the distribution of values d. This is good for creating a
% distribution of hte null hypothesis that the v1 and V2 are NOT different
%
%  nperms =  number of permutations
% bootfun = handle to the function on which to operate upon V1 and V2 - it
% assumes that bootfun only takes 2 variables as inputs.
% V1 V2  = the variables to permute.
% val = any additional arguments that need to be passed in to the
% bootfun.
%
% cowen (2005)
%%$$$$$$$$$$$$$$$$$$$$$$$
d = zeros(nperms,1);
if nargin < 5
    for ii = 1:nperms
        Vp = randperm_cols([V1 V2]);
        d(ii) = bootfun(Vp(:,1),Vp(:,2));
    end
else
    for ii = 1:nperms
        Vp = randperm_cols([V1 V2]);
        d(ii) = bootfun(Vp(:,1),Vp(:,2),val);
    end
end