function [p, chi2, df, CramerV] = chi2_test(actual, expected)
% This should be perused by someone else to make sure that I am not doing
% something stupid.
% cowen - see crosstab.
for iT = 1:length(actual)
    v(iT) = ((actual(iT) - expected(iT)).^2)/expected(iT);
end
chi2 = sum(v);
df = (length(actual)-1)*1;
p = 1 - chi2cdf(chi2,df);
CramerV = sqrt(chi2/sum(actual)/(length(actual)-1));

% 
% % Alternatively, here is the crosstab approach... (Assumes actual and
% % expected are 2 vectors of data that provide you with category counts.
% 
% u1 = unique(actual);
% u2 = unique(expected)
% M = zeros(length(u1), length(u2))*nan;
% 
% for ii = 1:length(u1)
%     for jj = 1:length(u2)
%         
%         M(ii,jj) = sum(
%     end
% end
% 
% bins = 1:length(unique(actual));
% obsCounts = histc(actual,bins);
% 
% 
% [h,p2,st] = chi2gof(bins,'Ctrs',bins,...
%                         'Frequency',obsCounts, ...
%                         'Expected',expCounts);
%                     
                    
                                                