function N = Shift_by_peak_or_trough(M,shift_type, shift_range)
% function N = Shift_by_peak_or_trough(M,shift_type, shift_range)
% Give a matrix M where each row is a separate waveform or PSTH, shift the
% waveform to the left or right so that the peak or trough is always
% centered in the middle. This is the same as Align_on_peak
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
N = M*nan;
mid = floor(Cols(M)/2)+1;
if nargin < 2
    shift_type = 'peak';
end
if nargin < 3
    shift_range = [];
end
MM = M;

if ~isempty(shift_range)
    % Just shift based on the max or min in a narrow range.
    MM(:,1:(mid-shift_range)) = nan;
    MM(:,(mid+shift_range):end) = nan;
end

switch shift_type
    case 'peak'
        [mn, ix] = nanmax(MM,[],2);
    case 'trough'
        [mn, ix] = nanmin(MM,[],2);
end
ix(isnan(mn)) = mid;
shifts = ix-mid;
nC = Cols(M);
for iR = 1:Rows(M)
    if shifts(iR) > 0
        npts = nC - shifts(iR) + 1;
        N(iR,1:npts) = M(iR,shifts(iR):end);
    elseif shifts(iR) < 0
        npts = nC + shifts(iR) + 1;
        N(iR,abs(shifts(iR)):end) = M(iR,1:npts);
    end
end