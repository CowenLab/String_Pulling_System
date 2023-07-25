function p = ttest_matrix(X,Y)
p = zeros(1,size(X,2));
if nargin < 2
    for ii = 1:Cols(X)
        [~,p(ii) ] = ttest(X(:,ii));
    end
else
    for ii = 1:Cols(X)
        [~,p(ii) ] = ttest2(X(:,ii),Y(:,ii));
    end
end
