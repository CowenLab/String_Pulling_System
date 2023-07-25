function [Smx] = Frequency_bands_from_spectrogram(S,fq,fq_ranges,method, MIX)
% INPUT: S - where each ROW is a frequency and each COL is a sample (yes,
% opposite of what we usually do).
%ASSUMES POWER SPECTRUM HAS BEEN FLATTENED!!
% Given a power spectrum (with frequencies fq), extract the band within a
% range that has the maxiumum response. 
% Cowen 2016.
if nargin < 4
    method = 'mean';
end
if nargin < 5
    MIX = true(1,Cols(S));
end
mn = nanmean(S(:,MIX),2);
Smx = NaN(size(fq_ranges,1),size(S,2));
ix = NaN(1,size(fq_ranges,1));
for iR = 1:size(fq_ranges,1)
    IX = fq >= fq_ranges(iR,1) & fq <= fq_ranges(iR,2);
    new_fqs = fq(IX);
    V = S(IX,:);
    switch method
        case 'max'
            mn2 = mn(IX);
            [~, ix(iR)] = nanmax(mn2);
            Smx(iR,:) = S(ix(iR),:);
        case 'mean'
            Smx(iR,:) = nanmean(V);
        case 'max_pow'
            Smx(iR,:) = nanmax(V,[],1);
        case 'peak_freq'
            % presumes baseline subtraction.
            [~, ix] = nanmax(V,[],1);
            Smx(iR,:) = new_fqs(ix);
    end
end
