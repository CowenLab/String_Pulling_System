function P = Group_and_PETH(TDG,bins)
% Pass in data with time, data, and the grouping variable and compute a
% PETH with a given binning size at that grouping variable.
% 
TDG = sortrows(double(TDG),1);
u = unique(TDG(:,3));
P = zeros(length(u),length(bins))*nan;
% Why you ask? because interp1 requires that no diff is zero. 
% TDG(:,1) = TDG(:,1) + randn(size(TDG,1),1)./1e10;
% ix = find(diff(TDG(:,1)) == 0);
% if ~isempty(ix)
%     disp('Found duplicate timestamps, removing them');
%     TDG(find(ix)+1,:) = [];
% end
for iG = 1:length(u)
    IX = TDG(:,3) == u(iG);
    XY = TDG(IX,1:2);
    if size(XY,1) > 2
        for iB = 1:length(bins)-1
            IXB = XY(:,1) >= bins(iB) & XY(:,1) < bins(iB+1);
            P(iG,iB) = nanmean(XY(IXB,2));
        end
        %interp1(XY(:,1)',XY(:,2)',bins,'linear');
    end
end
