function sa = Sliding_Z_score(X, window_size,direction)
% Compute a sliding z score over the window window_size
%
% Input: Vector X or a matrix where each column needs to have a sliding average.
%
% Output: Returns a vector in which each element is the average over a window
% of window_size in the input vector. The output vector will be of a
% length of X with Nan's window_size less than the input vector.
if nargin == 2
    direction = 1;
end

sa = zeros(size(X))*nan;
[n_rows,n_cols] = size(X);
%wsd2 = round(window_size/2);
if direction ==1
    for ii = 1:(n_rows-window_size)
        sa(ii+window_size,:) = (X(ii+window_size,:) - mean(X(ii:ii+window_size,:)))./(std(X(ii:ii+window_size,:))+eps) ;
    end
elseif direction ==-1
    for ii = (window_size+1):n_rows
        sa(ii,:) = (X(ii,:) - mean(X((ii-window_size):ii,:)))./(std(X((ii-window_size):ii,:))+eps) ;
    end
else
    error('WHAT!!?!?!?!?!!')
end
%
% for ii = 1:wsd2
%     wsd2 = round(ws
%     sa(ii+wsd2) = sum(X(ii-:ii+window_size - (windowsize-ii)))/window_size ;
% end

% if (size(X,1) == 1 | size(X,2) == 1)
%     X_length = length(X);
%     %wsd2 = round(window_size/2);
%     for ii = 1:(X_length-window_size)
%         sa(ii+window_size) = (X(ii+window_size) - mean(X(ii:(ii+window_size))))/(std(X(ii:ii+window_size))+eps) ;
%         %sa(ii+round(window_size/2)) = mean(X(ii:ii+window_size)) ;
%         %ssd(ii) = sum(X(ii:ii+window_size))/window_size ;
%     end
%     %
%    % for ii = 1:wsd2
%    %     wsd2 = round(ws
%    %     sa(ii+wsd2) = sum(X(ii-:ii+window_size - (windowsize-ii)))/window_size ;
%    % end
% else % it's a matrix
%     for ii = 1:size(X,2)
%         sa(:,ii) = Sliding_Z_scores(X(:,ii),window_size);
%     end
% end
