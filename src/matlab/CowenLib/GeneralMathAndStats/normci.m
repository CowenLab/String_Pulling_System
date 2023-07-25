function [mn,ci,se] = normci(D, dim)
%function [mn,ci,se] = normci(D);
% return the mean and confidence intervals (SEM) for the matrix D
%cowen
%
% Also see... 
if nargin < 2
    dim = 1;
end
if isempty(D)
    mn = [];
    se = [];
    ci = [];
    return
end

if iscell(D)
    mn = zeros(1,length(D))*nan;
    for ii = 1:length(D)
        mn(ii) = nanmean(D{ii},dim);
        se = Sem(D{ii});
    end
else
    se = Sem(D,dim);
    mn = nanmean(D,dim);
end

if ndims(mn) > 2
    mn = squeeze(mn);
    se = squeeze(se);
end

ci = [mn + se; mn-se];
