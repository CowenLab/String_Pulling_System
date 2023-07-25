function [sa,idx] = Sliding_average(X, window_size, center_location, binshift)
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
if nargin < 4
    binshift = 1;
end

if nargin < 3
    center_location = 1;
end
if (size(X,1) == 1 | size(X,2) == 1)
    X_length = length(X);
    switch center_location
        case -1 % Look behind
            startpt = window_size;
            endpt = X_length;
            backshift = window_size-1;
            foreshift = 0;
        case 0 % Center 
            wsd2 = round(window_size/2);
            startpt = wsd2;
            endpt = X_length - wsd2;
            backshift = wsd2-1;
            foreshift = wsd2;
        case 1 % Look ahead
            startpt = 1;
            endpt = X_length-window_size;
            backshift = 0;
            foreshift = window_size-1;
        otherwise
            error('Wrong center parameter -1 0 or 1')
    end
    sa = zeros(ceil(length(X)/binshift),1)*nan;
    idx = sa;
    if binshift == 1
        for ii = startpt:endpt
            sa(ii) = sum(X(ii-backshift:ii+foreshift));
            idx(ii) = ii-backshift;
        end
    else
        count = 1;
        for ii = startpt:binshift:endpt
            sa(count) = sum(X(ii-backshift:ii+foreshift));
            idx(count) = ii-backshift;
            count = count + 1;
        end
    end
    % normalize to rate.
    sa = sa/window_size;
else % it's a matrix
    for ii = 1:size(X,2)
        [sa(:,ii), idx] = Sliding_average(X(:,ii),window_size,center_location,binshift);
    end
end