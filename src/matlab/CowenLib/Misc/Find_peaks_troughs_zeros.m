function [PeaksIdx,TroughsIdx,ZeroUpIdx, ZeroDownIdx] = Find_peaks_troughs_zeros(M)
% [peaks,troughs,zeroups, zerodowns] = Find_peaks_troughs_zeros(M)
%
% Find the indices of the peaks, troughs, and zero crossings (going up and down
% for a vector of data (only works on vectors at this time.)
%
% ASSUMPTIONS: ONLY ONE PEAK OR TROUGH BETWEEN ZERO CROSSINGS>
%  ASSSUMES DATA IS CENTERED AT ZERO.
%
% INPUT: Data that has some peaks and troughs in it.
% OUTPUT: indices of peaks, troughs, and zero crossings
%
% cowen 2018
% zci = @(v) find(v(:).*circshift(v(:), [-1 0]) <= 0);                    % Returns Zero-Crossing Indices Of Argument Vector

% Make it a column vector.
M = M(:) - nanmean(M);
% zx = zci(M);                                                         % Approximate Zero-Crossing Indices

% de1 = [diff(M); 0];   % backward derivative
% de2 = [0; diff(M)];   % forward derivative

% %finding peaks
% PeaksIdx    = find(de1 < 0 & de2 > 0);  % finds indices of local peaks
% if nargout > 1
%     TroughsIdx  = find(de1 > 0 & de2 < 0);
% end
ZeroDownIdx = find(M<0 & [0;M(1:end-1)]>0)-1;
% Subtract one so that the transition for
% the up and the down are at the same level (otherwise they will be off by on for each
% cycle.
ZeroUpIdx   = find(M>0 & [0;M(1:end-1)]<0);

% peaks
if ZeroDownIdx(1) < ZeroUpIdx(1)
    ZeroDownIdx(1) = [];
end
% cnt  = 1;
PeaksIdx = nan(size(ZeroUpIdx));
for iP = 1:length(ZeroUpIdx)-1
    [~,ix] = max(M(ZeroUpIdx(iP):ZeroDownIdx(iP)));
    PeaksIdx(iP) = ZeroUpIdx(iP) + ix - 1;
end
PeaksIdx = PeaksIdx(1:iP);

TroughsIdx = nan(size(ZeroDownIdx));
for iP = 1:length(ZeroDownIdx)-1
    [~,ix] = min(M(ZeroDownIdx(iP):ZeroUpIdx(iP+1)));
    TroughsIdx(iP) = ZeroDownIdx(iP) + ix - 1;
end
TroughsIdx = TroughsIdx(1:iP);

if nargout == 0
    figure
    plot(1:length(M),M,'k');
    hold on
    plot(ZeroDownIdx,M(ZeroDownIdx),'r+')
    plot(ZeroUpIdx,M(ZeroUpIdx),'g^')
    plot(PeaksIdx,M(PeaksIdx),'m*')
    plot(TroughsIdx,M(TroughsIdx),'c*')
end
if 0
    % I took this out as it would lead to situations where there are 2
    % peaks in a row. or two troughs in a row.
    % IF there are any peaks or troughs that also happen to be a zero crossing,
    % eliminate them.
    [~,iA,iB] = intersect(PeaksIdx, ZeroDownIdx);
    if ~isempty(iA)
        PeaksIdx(iA) = [];
        ZeroDownIdx(iB) = [];
    end
    [~,iA,iB] = intersect(PeaksIdx, ZeroUpIdx);
    if ~isempty(iA)
        PeaksIdx(iA) = [];
        ZeroUpIdx(iB) = [];
    end
    [~,iA,iB] = intersect(TroughsIdx, ZeroUpIdx);
    if ~isempty(iA)
        TroughsIdx(iA) = [];
        ZeroUpIdx(iB) = [];
    end
    [~,iA,iB] = intersect(TroughsIdx, ZeroDownIdx);
    if ~isempty(iA)
        TroughsIdx(iA) = [];
        ZeroDownIdx(iB) = [];
    end
end
