function [Cxy,fs] = mscohere_no_nan(L1,L2,hn,overlap,nfft,sFreq)
% function [Cxy,fs] = mscohere_no_nan(L1,L2,hn,overlap,nfft,sFreq)
% Runs mscohere but ignores periods with nans. Does this by looking for
% nan-free blocks of a minimum duration and then separately performs
% mscohere on each nan-free block. The results of mscohere are weighted by
% the duration of each block so that very small blocks do not contribute as
% much as large blocks (see WT in the function).
%
% A valid window needs to be at least as long as 2 hanning windows
%
% Cowen 2016
min_len = length(hn)*2;
IX = isnan(L1+L2);
if any(IX)
    if length(nfft) == 1
        fs = NaN(nfft/2+1,1);
    else
        fs = nfft;
    end
    Cxy = NaN(size(fs));
    
    [~,G] = find_intervals(IX,.5);
    G(:,1) = G(:,1) + 1; % to correct for an ideosyncracy in find_intervals
    G(:,2) = G(:,2) - 1;
    
    GOODIX = G(:,2)-G(:,1) > min_len;
    G = G(GOODIX,:);
    % determine how much to weigh each chunk.
    
    if ~isempty(G)
        D = G(:,2)-G(:,1);
        wt = D/sum(D);
        tmp = NaN(numel(fs), size(G,1));
        for iR = 1:size(G,1)
            if diff(G(iR,:)) > hn
                [tmp(:,iR),fstmp] = mscohere(L1(G(iR,1):G(iR,2)),L2(G(iR,1):G(iR,2)),...
                    hn,overlap,nfft,sFreq);
                if ~any(isnan(fstmp))
                    fs = fstmp;
                end
            else
                tmp(:,iR) = nan;
            end
        end
        WT = repmat(wt',length(fs),1);
        Cxy = nansum(tmp.*WT,2);
    end
else
    [Cxy,fs] = mscohere(L1,L2,hn,overlap,nfft,sFreq);
end