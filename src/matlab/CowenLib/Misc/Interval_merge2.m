function O = Interval_merge2(I,th)
% merge inervals where the end of one intervals overlaps or is the same as
% teh start of the next interval.
if nargin < 2
    th = 0;
end
I = sortrows(I);
O = [];
O(1) = I(1);
cnt = 1;
for ii = 1:(Rows(I)-2)
    if I(ii+1,1)-I(ii,2) <= th
    else
        O(cnt,2) = I(ii,2);
        O(cnt+1,1) = I(ii+1,1);
        cnt = cnt + 1;
    end
   
end
O(cnt,2) = I(end,2);