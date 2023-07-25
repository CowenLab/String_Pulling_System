function c= XCorr_coeff(A, B, one_side_width_bins)
%function c= XCorr_coeff(A, B, one_side_width_bins)
% INPUT :
%   A and B vectors for which you wish to correlate.
%   one_side_width_bins = the number of bins to one side of the 0 lag.
% OUTPUT:
%   c = cross correlations using the correlation coefficient. 
%          (total length = one_side_width_bins*2 + 1)
%
% NOTE: this is the same as xcorr(A,B,one_side_width_bins,'coeff') except that it doesnt
%       return a vector of length A. If you don't have the sig processing toolbox, use this.

% cowen
error(nargchk(3,3,nargin));

if size(A)~=size(B)
    error('A and B must be the same size');
end

one_side_width_bins = one_side_width_bins + 1;
theend = length(A);
if size(A)~=size(B)
    error('A and B must be the same size');
end

c1 = zeros(1,one_side_width_bins);
c2 = zeros(1,one_side_width_bins);

for ii = 1:one_side_width_bins
    a = corrcoef(B(ii:theend),A(1:(theend - ii+1)));
    c1(ii) = a(2,1);
end
for ii = 1:one_side_width_bins
    a = corrcoef(A(ii:theend),B(1:(theend - ii+1)));
    c2(ii) = a(2,1);
end

c1 = c1(:); c2 = c2(:);
c = [c1(end:-1:1);c2(2:end)];
