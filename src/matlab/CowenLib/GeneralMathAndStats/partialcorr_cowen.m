function [cc pp]= partialcorr_cowen(M,P)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Why does this give larger r values than without partialling?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
GIX = ~isnan(sum([M P],2));
if size(M,1)-sum(GIX) > size(M,1)/3
    disp('partialcorr_cowen: A TON OF BAD RECORDS- REVISIT YOUR CRAPPY DATA')
end
if sum(GIX) < 7
    disp(['Only ' num2str(sum(GIX)) ' datapoints. Returning nan.'])
    cc = nan; % Don't even bother - it will be invalid anyway.
    return
end
[cc pp] = partialcorr(M(GIX,:),P(GIX,:));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the user just wants a correlation between two variables, they don't
% want a square matrix.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if size(M,2) == 2
    if size(cc,1) > 1
        cc = cc(2);
        pp = pp(2);
    else 
        cc = nan;
        pp = nan;
    end
end

