function [ix] = find_a_run(P,n)
% Finds a run of ones of n long (going from left to right) in vector P of
% zeros and ones. IT ONLY FINDS THE FIRST RUN!!!!
%
% e.g. P = [0 0 1 1 0 1 1 1 0 0 0 1 1 1 1 1 1 1]
% the first run of 2 would start at ix = 3, the first run of 3 (and second
% run of 2) would be at ix = 6 and the first run of > 3 is at ix = 12.
% 
% Cowen 2011
if nargin < 2
    error('Requires 2 parameters')
end
if any(size(P) == 1);
else
    ix = zeros(1,Cols(P));
    for iC = 1:Cols(P)
        ix(iC) = find_a_run(P(:,iC),n);
    end
    return
end
count = 0;
ix = nan;
% Need 3 sig in a row to count.
for ii = 1:length(P)
    if P(ii) == 1
        count = count + 1;
    else
        count = 0;
    end
    if count > n-1
        ix = ii - (n-1);
        break
    end
end

if  0 
     P = [0 0 1 1 0 1 1 1 0 0 0 1 1 1 1 1 1 1]
     n = 3
     find_a_run(P,n)
end
      