function order_ix = sort_by_pdist(P_dist)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% input - output of pdist.
% output - indices for resorting the elements in the original data
%  so that the data is ordered according to local similarity, starting with
%  the most similar pair at the top.
%
% what a piece of crappy code. Could probably be done in one line.
% DO NOT TRUST THIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sf = tril(squareform(P_dist+eps));
[r,c] = find(Sf);

Sf(find(Sf ==0)) = inf;
order_ix = zeros(size(Sf,1),1)*nan;
%
[mn ] = min(min(Sf));
[order_ix(1) order_ix(2)] = find(Sf==mn,1,'first');
%if nargout ==0
    Sf(order_ix(1),:) = inf;
    Sf(:,order_ix(1)) = inf;
    %imagesc(Sf)
    %
    for ii = 3:size(Sf,1)
        %
        [mn order_ix(ii)] = min(Sf(:,order_ix(ii-1))');
        %
        Sf(order_ix(ii-1),:) = inf;
        Sf(:,order_ix(ii-1)) = inf;
        order_ix(ii)
        %imagesc(Sf)
        %drawnow
        %    pause
    end
%end

