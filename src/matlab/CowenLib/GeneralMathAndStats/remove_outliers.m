function [M, ix, goodix] = remove_outliers(M, fac)
% function M = remove_outliers(M, fac)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Outlier Identification: Remove them. An outlier is defined using the
%  standard stats definition: less than Q1 ? 1.5 × IQR or greater
%  than Q3 + 1.5 × IQR. Luckily, REGRESS treats Nans as missing
%  values so no need to remove the rows with outliers.
%
% OUTLIERS ARE REPLACED WITH NaNs so the size of M stays the same.
% 
% INPUT: M - matrix where each col is a variable, each row a sample. Works
%  on each col independently and converts outliers to Nans. The new matrix
%  is returned in O.
% OUTPUT: O - the outlier free matrix with outliers replaced with NANs
%
%  ix = the indices of the outliers.
% cowen (2005)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 1 || isempty(fac)
    fac = 1.5;
end
if (size(M,1) < 4)
    disp('Too few samples')
    return;
end
iq = iqr(M);
pt_25 = prctile(M,25);
pt_75 = prctile(M,75);
lower_thresh = pt_25 - fac * iq;
upper_thresh = pt_75 + fac * iq;
for iC = 1:size(M,2)
    ix = find( M(:,iC) > upper_thresh(iC) | M(:,iC) < lower_thresh(iC));
    if ~isempty(ix)
        M(ix,iC) = nan;
    end
end

if nargout == 3
    goodix = setdiff(1:Rows(M),ix(:)');
end
