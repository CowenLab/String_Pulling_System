function [CC,intervals,Freq_pairs] = SPEC_cross_fq_coupling_ppc(POWS, pow_interval_recs, frequencies)
% function [CC,intervals,Freq_pairs] = SPEC_cross_fq_coupling_ppc(POWS, pow_interval_recs, frequencies)
%
% Create a moving power-power measure by computing the correlation
% coefficient between all frequency combinations for a given interval in
% time. Pass in a n X fq matrix of power, a window size in samples, and the
% labels for each frequency as a vector of length nCols of POWS.
% 
%
% Cowen 2016
UPIX = triu(ones(Cols(POWS)),1)>0;
R = repmat(frequencies(:)',length(frequencies),1);
C = repmat(frequencies(:),1,length(frequencies));
Freq_pairs = [R(UPIX) C(UPIX)];
% ensure equal spaced intervals and ensure that we go all the way to the
% end of the data.
intervals = floor(linspace(1, Rows(POWS),round(Rows(POWS)/pow_interval_recs)));

CC = nan(length(find(UPIX)),length(intervals));
for ii = 2:length(intervals)
    P = POWS(intervals(ii-1):intervals(ii),:);
    P = P(~isnan(sum(P,2)),:);
    if Rows(P)>20 % Don't bother with very small sample sizes - the corr won't be valid anyway.
        tmp = corrcoef(P);
        CC(:,ii) = tmp(UPIX);
    end
end
CC = CC';