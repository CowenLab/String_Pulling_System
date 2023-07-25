function [ed,mn,c] = Euclid_dist(A,B)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function [ed,mn,c] = Euclid_dist(a,B)
% INPUT: 
%   a scalar or vector to compare (one by one) to all of the locations
%   speicified in B.
% OUTPUT: 
%   ed = euclid distance of each element in A to each element in B - by
%   column only.
%   mn = the minimum distance of each element in A to all elelments in B
%   c  = the index of the min.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ed = zeros(Rows(A),Rows(B))*nan;
mn = zeros(Rows(A),1)*nan;
c = zeros(Rows(A),1)*nan;
for ii = 1:Rows(A)
    rep  = repmat(A(ii,:), Rows(B),1);
    d = sqrt(sum((rep-B).^2,2));
    ed(ii,:) = d';
    [mn(ii),c(ii)] = min(d);
end