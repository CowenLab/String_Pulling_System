function S = trimmean_cowen(M,perc, dim)
% trimmed mean - better than trimmean because 1) trimmean still gives you
% nans despite it supposed to ignore them and 2) trimmean does not allow
% you to set the lower and upper bounds. Works independently on each
% column. perc is a vector of length 2 with the lower and upper
% percential limits from which to restrict the data.
%
% Cowen 2016s

% PRESUMES averaging by Column.
if nargin < 3
  dim = 1;
end

if nargin < 2
    perc = [5 95];
end
if length(perc) == 1
    perc = [perc/2 100-perc/2];
end

if ndims(M) > 2
    disp('This is doing wierd things for 3+ dim matricies')
end

if any(size(M)==1)
    %%%???

    p = prctile(M,perc,dim);
    S  = nanmean(M(M > p(1) & M < p(2)),dim);
else
    S = NaN(1,size(M,2));
    for iC = 1:size(M,2)
        p = prctile(M(:,iC),perc);
        IX = M(:,iC) > p(1) & M(:,iC) < p(2);
        S(iC) = nanmean(M(IX,iC));
    end
end
