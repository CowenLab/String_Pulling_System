function O = Align_and_interp_on_one_event(M,x_zerod,new_x,method)
% re-interpolate the data in M that has been re-zerod (by subtrackgin an
% alignment time) to a new x.
% Do some housekeeping like interpolating across NANs and INFs
% Cowen 2019
if nargin < 4
    method = 'linear';
end
O = nan(length(new_x),Cols(M));
new_x = new_x(:);
for iCol = 1:Cols(M)
    BIX = isnan(M(:,iCol)) | isinf(M(:,iCol));
    if mean(double(BIX)) > .5
        % 50% of data is crap. screw it.
        O(length(new_x),iCol) = nan;
        continue
    end
    OUTIX = new_x >= x_zerod(1) & new_x <= x_zerod(end);
    O(OUTIX,iCol) = interp1(x_zerod(~BIX),M(~BIX,iCol),new_x(OUTIX),method); % ensures timestamps are EXACTLY The same for all sets.
end
