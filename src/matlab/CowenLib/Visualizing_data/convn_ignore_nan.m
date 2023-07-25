function Cout = convn_ignore_nan(C,kernel)
% igonore nans
% cowen 2016
NIX = sum(isnan(C),2);
in = find_intervals(~NIX,.5);
Cout = C;
for ii = 1:Rows(in)
    if in(ii,2) - in(ii,1) > length(kernel)
        Cout(in(ii,1):in(ii,2),:) = convn(C(in(ii,1):in(ii,2),:),kernel,'same');
    end
end
if nargout == 0
    imagesc(Cout)
end