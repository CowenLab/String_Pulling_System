function [cc,x] = Cross_corr(ts1, ts2, binsize, n_lags, varargin)
% function [ac,x] = Cross_corr(ts1, ts2, binsize, n_lags, varargin)
%
% Standard cross-correlogram for spike trains.
%
% INPUT: ts1,ts2 = timestamp vectors (sorted)
%        binsize = binsize for binning timestamps. (same units as ts)
%        n_lags = n_lags in the xcorr. 
%
% OUTPUT: cc = cross correlation 
%         x = the x axis (whatever units ts and binsize are in).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
plot_it = false;
scaleopt = 'none';
% scaleopt = 'coeff';

Extract_varargin

if iscell(ts1)
    cc = nan(lenght(ts1),n_lags);
    for ii = 1:lenght(ts1)
        [cc(ii,:),x] = Cross_corr(ts1{ii},ts2{ii}, binsize, n_lags,'scaleopt',scaleopt);
    end
    return
end

cc = nan(n_lags,1);

if isempty(ts1) || isempty(ts2)
    return
end

edges = min([ts1(1) ts2(1)]):binsize:max([ts1(end) ts2(end)]);
c1 = histcounts(ts1,edges);
c2 = histcounts(ts2,edges);
[cc, x] = xcorr(c1,c2,n_lags,scaleopt);
if all(c1==c2)
    % autocorr
    cc(x==0) = nan;
end
x = x*binsize; % convert to units of ts

if plot_it
    % figure
    stairs(x,cc,'Color',[0 0 0 ],'LineWidth',1)
    axis tight
    box off
    plot_vert_line_at_zero
    set(gca,'FontSize',8)
    % ylabel([scaleopt])
end