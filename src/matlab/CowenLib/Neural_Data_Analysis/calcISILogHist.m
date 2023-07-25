function [bins, ISIlog_hist_norm, allISI] = calcISILogHist(peakTrn, nBinsPerDec, sf)
% calcISILogHist.m
% by Valentina Pasquale - Italian Institute of Technology, March 2008
% %%
% ISI histogram computation for a single spike train (logarithmic binning)
% %%
% ARGUMENTS:
% %%
% peakTrn:  sparse array ([number of samples x 1]), containing 1
%           when a spike is present, 0 elsewhere
% nBinsPerDec:  number of bins per decade
% sf:           sampling frequency (samples per second)
% %%
% RESULTS:
% %%
% bins: series of bins (logarithmically spaced)
% ISIlog_hist_norm: normalized logarithmic histogram of ISI
% allISI: all inter-spike intervals
% %%
% See also: V. Pasquale, S. Martinoia, M. Chiappalone "A self-adapting approach for the detection of bursts
% and network bursts in neuronal cultures", J. Comput. Neurosci., DOI
% 10.1007/s10827-009-0175-1.
%% INITIALIZE RESULTS
bins = [];
ISIlog_hist_norm = [];
allISI = [];
%% CHECK ARGUMENTS' TYPE
if ~isvector(peakTrn)
    error('The first argument must be a 1-by-N or N-by-1 vector where N >= 1.')
else 
    peakTrn = peakTrn(:);   % column vector
end
if ~(isscalar(nBinsPerDec) && ~(mod(nBinsPerDec,1))) || nBinsPerDec <= 0
    error('The second argument must be a positive scalar integer.')
end
if ~(isscalar(sf) && ~(mod(sf,1))) || sf <= 0
    error('The third argument must be a positive scalar integer.')
end
%% ISI HISTOGRAM COMPUTATION
ts = find(peakTrn);     % find spike times
if numel(ts) > 1 % if there is at least two spikes
    allISI = diff(ts)/sf*1000;                     % ISIs in [ms]
    maxWin = ceil(log10(max(allISI)));             % [ms]; rounded to the nearest decade towards +inf
    bins = logspace(0,maxWin,maxWin*nBinsPerDec);    % equally spaced logarithmic bins
    ISIlog_hist = histc(allISI,bins);                     % computes hist
    ISIlog_hist_area = sum(ISIlog_hist);
    if ISIlog_hist_area
        ISIlog_hist_norm = ISIlog_hist./ISIlog_hist_area;    % normalization
        ISIlog_hist_norm = ISIlog_hist_norm(:);
        bins = bins(:);
    end
end