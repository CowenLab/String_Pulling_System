function [sa,ssd,idx] = Sliding_average(X, window_size, binshift)
%function [sa,ssd,idx] = Sliding_average(X, window_size, binshift)
% Compute a sliding average
%
% Input: Vector X or a matrix where each column needs to have a sliding average.
%   binshift is the amount to shift forward after every average.
%   center_location -- where the average should go-- at the beginning,
%   center or end of the window.
%   window_size -- the number of bins to average over.
%
% Output: Returns a vector in which each element is the average over a window
% of window_size in the input vector. The output vector will be of a
% length of X with Nan's window_size less than the input vector.
%   idx are the indices in X which correspond to the start of each window.
%   if binshift = 1 then this will just be 1:size(X,1), otherwise, it will
%   skip.
% I could get around the edge issue by just adding some extra data to the
% front and back where the extra data would just be repetitions of the mean
% of the nearest window. This would also simplify things as i could start
% and end at the same place. The amount on each edge would be
% windowsize/binshift bins. and set equal to first windowsize average and
% last windowsize average.
if nargin < 3
    binshift = 1;
end
if (size(X,1) == 1 | size(X,2) == 1)
    [sa, ssd, idx] = Sliding_average_mex(X, window_size, binshift);
else % it's a matrix
    for ii = 1:size(X,2)
       % [sa(:,ii),ssd(:,ii),idx] = Sliding_average2(X(:,ii),window_size,binshift);
       [sa(:,ii), ssd(:,ii), idx] = Sliding_average_mex(X(:,ii), window_size, binshift);
    end
end