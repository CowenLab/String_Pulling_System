function [cc,p] = corrcoef_cowen(M, corr_type)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Gets rid of a few tedious lines in the builtin corrcoef function. Also,
% returns nan if you have less than 7 samples which is safer than giving
% you false hope.
%
% cowen 2012
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2
    corr_type = 'pearsons';
end

GIX = ~isnan(sum(M,2));
if size(M,1)-sum(GIX) > size(M,1)/3
%     disp('corrcoef_cowen: A TON OF BAD RECORDS- REVISIT YOUR CRAPPY DATA')
end
if sum(GIX) < 4
%     disp(['Only ' num2str(sum(GIX)) ' datapoints. Returning nan.'])
    cc = nan; % Don't even bother - it will be invalid anyway.
    p = nan;
    return
end
switch corr_type
    case 'pearsons'
        [cc,p] = corrcoef(M(GIX,:));
    case 'spearmans'
        [cc,p] = corr(M(GIX,:), 'type', 'Spearman');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the user just wants a correlation between two variables, they don't
% want a square matrix.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if size(M,2) == 2
    if size(cc,1) > 1
        cc = cc(2);
        p = p(2);
    else 
        cc = nan;
        p = nan;
    end
end