function [O, mid] = Align_on_peak(M)
% function O = Align_on_peak(M)
% For each ROW, align the matix to the peak of each row. 
% replace shifts that go out of bounds with nans
%
% Cowen. 2016
mid = round(size(M,1)/2);
[~,ix] = max(M,[],1);
O = zeros(size(M))*nan;
for ii = 1:length(ix)
    v = mid-ix(ii);
    O(:,ii) = circshift(M(:,ii),[v 0]);
     if v > 0
         O(1:v,ii) = nan;
     elseif v < 0
         O((end-abs(v)):end,ii) = nan;
     end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout == 0
    subplot(1,2,1)
    imagesc(M)
    subplot(1,2,2)
    imagesc(O)
end
