function p = ranksum_matrix(A,B)
for iCol = 1:Cols(A)
    p(iCol) = ranksum(A(:,iCol), B(:,iCol));
end