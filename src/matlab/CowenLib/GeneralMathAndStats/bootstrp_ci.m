function [ci] = bootstrp_ci(I,nboot,conf_limits,central_tend_fun)
% function [ci] = bootstrp_ci(I,nboot,conf_limits)
%
% bootstrp confidence intervals (95%)
%
% WITH REPLACEMENT
%
% FYI: Resampling cannot improve point estimates.
%
% INPUT:
%
% I = sample data. If a matrix, then each col is treated independently.
% nboot = number of times to run the bootstrap. 
% conf_limits - defaults to [5 95] - 90% confidence interval
% central_tend_fun = function for computing the central tendency after each
%   bootstrap. Default is @nanmean.
%
% Cowen 2016
%
% TODO: if you do NOT want replacement, then y = datasample(data,k) with
% the 'Replace',false option is probably the way to go.
%
if nargin == 0
    % test
    I = [30, 37, 36, 43, 42, 43, 43, 46, 41, 42];
end
if nargin < 2
    nboot = 1000;
end
if nargin < 3
    conf_limits = [5 95];
end
if nargin < 4
    central_tend_fun = @nanmean;
end

if min(size(I)) > 1
    % If the user passes in a matrix, do this independently on each col.
    ci = zeros(size(I,2),2);
    for iC = 1:size(I,2)
        ci(iC,:) = bootstrp_ci(I(:,iC),nboot,conf_limits);
    end
    return
end
% rng default  
mn = central_tend_fun(I);
[M] = bootstrp(nboot,central_tend_fun, I );
M = M - mn;
devs = prctile(M,conf_limits);
ci = devs + mn;

if nargout == 0
    clf
    hist(I,20)
    hold on
    a = axis;
    plot([ci(1) ci(1)], a(3:4),'-b')
    plot([ci(2) ci(2)], a(3:4),'-r')
    plot([mn mn], a(3:4),'-g')
end
