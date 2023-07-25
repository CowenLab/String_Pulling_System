function C = conv_filter(C,kernel)
% Perform a convolution filter with the passed in kernel 
% deal with edge problems by padding the edges with extra data.
%
% Convolves each column if it is a matrix. 
% cowen 2006
if isempty(C)
    return
end
C = C'; % Transform as it visually makes more sense for me to convolve along rows.
flip_back = false;
if min(size(C))==1
    % it's a vector.
    if size(C,2) == 1
        flip_back = true;
    end
    C = C(:)';
end
ncol = size(C,2);
window_size = length(kernel);
medL = nanmean(C(:,1:window_size),2);  % Median isn't good with spike counts as it will be zero if the binsize is small. Mean does not have that problem. 
medR = nanmean(C(:,ncol:-1:(ncol -(window_size-1))),2);
CpadL = repmat(medL,1,window_size);
CpadR = repmat(medR,1,window_size);
% Old way by reversing exactly replicating the data - subject to artifact
% like responses.
%CpadL = C(:,window_size:-1:1);
%CpadR = C(:,ncol:-1:(ncol -(window_size-1)));
C = convn([CpadL C CpadR]',kernel,'same')';
C = C(:,(window_size+1):(end-window_size))'; % Transpose back
if flip_back
    C = C';
end