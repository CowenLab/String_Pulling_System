function [mn, ci] = stdci(D, dim)
%function [mn ci] = stdci(D)
% Confidence intervals - mean and std.
if nargin < 2
    dim = 1;
end

if isempty(D)
    mn = [];
    se = [];
    ci = [];
    return
end
mn = nanmean(D,1);
sd = nanstd(D,[],dim);
ci = [mn + sd; mn - sd];