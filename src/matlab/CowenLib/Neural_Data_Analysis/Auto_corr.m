function [ac,x] = Auto_corr(ts, binsize, n_lags, varargin)
% function [ac,x] = Auto_corr(ts, binsize, n_lags, varargin)
%
% Standard auto-correlogram for spike trains.
%
% NOTE: This is a matlab version of our old tried and true AutoCorr in mex.
% this will work on the HPC which does not play nice with mex files.
% 
% INPUT: ts = timestamps (sorted)
%        binsize = binsize for binning timestamps. (same units as ts)
%        n_lags = n_lags in the xcorr. 
%
% OUTPUT: ac = autocorr (nan at lag=0 and only half is returned).
%         x = the x axis (whatever units ts and binsize are in).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
plot_it = false;
scaleopt = 'none';
% scaleopt = 'coeff';

Extract_varargin

if iscell(ts)
    ac = nan(lenght(ts),n_lags);
    for ii = 1:lenght(ts)
        [ac(ii,:),x] = Auto_corr(ts{ii}, binsize, n_lags,'scaleopt',scaleopt);
    end
    return
end

ac = nan(n_lags,1);
x = linspace(binsize/2,(n_lags*binsize) - binsize/2,n_lags)' ; % bin centers.

if isempty(ts)
    return
end

edges = ts(1):binsize:ts(end);
if length(edges) > 1
    c = histcounts(ts,edges);
    [ac] = xcorr(c,n_lags,scaleopt);
    ac = ac((n_lags+2):end);
else
    ac = nan(n_lags,1);
end

if plot_it
    % Compare to AutoCorr. Should be the same.
    % [ac2,x2] = AutoCorr(ts, binsize, n_lags);
    stairs(x,ac)
    axis tight
    box off
    ylabel(['scale: ' scaleopt])
end