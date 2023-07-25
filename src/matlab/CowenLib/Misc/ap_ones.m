function o = ap_ones(F, front_or_back, val)
% function o = ap_ones(F, front_or_back, val)
% Append ones - usefull for calls to regress.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2
    front_or_back = 'front';
    val = 1;
end
if nargin < 3
    val = 1;
end
switch(front_or_back)
    case 'front'
        o = [ones(size(F,1),1)*val F];
    case 'back'
        o = [F ones(size(F,1),1)*val];
    otherwise
        error('Unknown value - front or back only')
end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
