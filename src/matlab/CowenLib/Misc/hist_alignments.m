function [H,x] = hist_alignments(A,x)

if iscell(A)
    if isscalar(x)
        AA = cell2mat(A);
        x = min(A):x:max(A);
    end
    
    H = zeros(length(A),length(x));
    for iF= 1:length(A)
        H(iF,:) = hist_alignments(A{iF},x);
    end
    return
else
    if isscalar(x)
        x = min(A):x:max(A);
        H = histc(A,x);
    end
end