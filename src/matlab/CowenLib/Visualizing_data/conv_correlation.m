function C2 = conv_correlation(C,kernel)
%  C2 = conv_correlation(C,kernel)
% INPUT: C matrix where each col is a vector of data to correlate/convolve with (each
% col is independent)
%        kernel - the kernel to correlate/convolve with the columns in c.
%
% OUTPUT: the convolved data, same size as C, but padded with nans where
% the results are ambiguous.
% slide the kernel over C, but perform a correlation at each point.
%  the result is centered on the middle of the kernel.
%
% cowen 2008
if isempty(C)
    return
end
C = C'; % Transform as it visually makes more sense for me to convolve along rows.
C2 = C*nan;
ncol = size(C,2);
window_size = length(kernel);
kernel = kernel(:)';
% THIS IS REALLY SLOW!
for iRow = 1:Rows(C)
    for iCol = 1:(ncol-window_size)
        CC = corrcoef(kernel,C(iRow ,iCol:(iCol+window_size-1)));
        C2(iRow ,iCol + (window_size-1)/2) = CC(2,1); % centers the result
    end
end
