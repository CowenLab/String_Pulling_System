function S = trimstd(M,perc,dim)
% trimmed standard devaition - works sort of like trimmean. Works independently on
% each column. perc is a vector of length 2 with the lower and upper
% percential limits from which to restrict the data.
% also - I maed a mirror - trimmean_cowen
% Cowen 2016s
if length(perc) == 1
    perc = [perc/2 100-perc/2];
end
if nargin < 3
    dim = 1;
end
if any(size(M)==1)
    p = prctile(M,perc);
    S  = nanstd(M(M > p(1) & M < p(2)),dim);
else
    if dim == 2
        M = M';
    end
    S = NaN(1,size(M,2));
    for iC = 1:size(M,2)
        p = prctile(M(:,iC),perc);
        IX = M(:,iC) > p(1) & M(:,iC) < p(2);
        S(iC) = nanstd(M(IX,iC));
    end
    if dim == 2
        M = M';
        S = S';
    end

end
