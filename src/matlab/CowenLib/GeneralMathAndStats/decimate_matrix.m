function O = decimate_matrix(M,factor)
% function O = Decimate_matrix(M,factor);
% uses the matlab decimate function to decimate an entire matrix by column.
% Ignores cols with nans
%
% Cowen
type = class(M);
if ~isa(M,'double')
    M = double(M);
    disp('Converted to double');
end

for iC = 1:Cols(M)
    if iC == 1
        m = M(:,iC);
        m(isnan(m)) = nanmean(m);
        if any (isnan(m))
            m = zeros(size(m));
        end
        o = decimate(m,factor);
        O = NaN(length(o),Cols(M));
        O(:,iC) = o(:);

    else
        m = M(:,iC);
        m(isnan(m)) = nanmean(m);
        if ~any(isnan(m))
            O(:,iC) =  decimate(m,factor);
        end
    end
end