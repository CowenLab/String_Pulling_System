function [m, ci] = expfitnan(M)
% Does expfit with nans
m = zeros(1,Cols(M));
ci = zeros(2,Cols(M));
for ii = 1:Cols(M)
    ix = find(~isnan(M(:,ii)));
    [m(ii) tmp] = expfit(M(ix,ii));
    ci(:,ii) = tmp;
end
