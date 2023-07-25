function OUT = Find_Intersection_On_Curve(M,cut_pt)
% Finds the two intersection points between a threhold line and a curve. 
% This is useful for determineing the width of a tuning curve.
% INPUT: M (a vector that is the curve)
%        cut_pt (the threshold to cut the curve at)
% OUTPUT: Two intersection points for the threshold (assumes you have a
% gaussian shaped curve).
%
% Cowen (2008)
OUT = zeros(1,2)*nan;
OUT(1) = find(M>cut_pt & [nan;M(1:end-1)]<=cut_pt, 1 );
tmp = find(M<cut_pt & [nan;M(1:end-1)]>=cut_pt, 1 )-1;
if isempty(tmp)
    tmp = length(M);
end
OUT(2) = tmp;
