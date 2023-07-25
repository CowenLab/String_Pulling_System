function [L, padix] = SPEC_pad_LFP_to_be_power_of_2(L)
% function [L, padix] = SPEC_pad_LFP_to_be_power_of_2(L)
%
% INPUT: LFP data and pad the end with zeros so that the length is 2 to the
% power of somethign so that FFT is sped up.
% % delete padix afterwards to get rid of the padding.%
%
% to speed up FFT, pad the Lfp signal with zeros.
if min(size(L))== 1
    nEl = length(L);
    f = ceil(log2(nEl));
    pad_len = 2^f - nEl;
    L(nEl+1:(nEl+pad_len)) = 0;
    padix = (nEl+1):length(L);
else
    % For matrices.
    f = ceil(log2(size(L,1)));
    nEl = size(L,1);
    pad_len = 2^f - nEl;
    L(nEl+1:(nEl+pad_len),:) = 0;
    padix = (nEl+1):size(L,1);
end
