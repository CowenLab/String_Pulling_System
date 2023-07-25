function p = signrank_matrix(M)
p = nan(1,Cols(M));
for ii = 1:Cols(M)
    GIX = ~isnan(M(:,ii));
    if sum(GIX)>2
        p(ii) = signrank(M(:,ii));
    end
end
