function eeg = CR2EEG(cr,no_tsd)

% eeg = CR2EEG(cr)
%
% converts lipa's CR structure (from ReadCR)
% to tsd structure
%

% ADR 1999
% status PROMOTED
% version 1.0
% cowen Sat Jul  3 14:59:47 1999
% Got rid of the diplay progress.
% cowen 2013 - you can ask to not create a tsd object.
% cowen 2016 - now detects irregularities in the timestamps  - whether
% the timestamps are increasing. This is an indicator that the files have
% been corrupted. 

if nargin < 2
    no_tsd = false;
end


blockSize = 512;
nBlocks = length(cr.ts);
dT = 1/cr.sFreq;

TIME = zeros(size(cr.dd))*nan;

for iBlock = 1:(nBlocks-1)
    %DisplayProgress(iBlock, nBlocks-1);
    TIME((blockSize * (iBlock-1) + 1):(blockSize * iBlock)) = ...
        linspace(cr.ts(iBlock), cr.ts(iBlock+1) - dT, blockSize);
end
GIX = ~isnan(TIME(:));
n = sum(~GIX);
if n > 0
    fprintf('WARNING: %d unallocated time points\n',n);
    
    TIME = TIME(GIX);
    cr.dd = cr.dd(GIX);
end


if any(diff(TIME) <=0)
    fprintf('WARNING: %d non-incremeting time. Your files may have been corrupted.\n',sum(diff(TIME)<=0))
end

if no_tsd
    eeg = [round(TIME(:)) cr.dd(:)];
else
    eeg = tsd(round(TIME), cr.dd);
end