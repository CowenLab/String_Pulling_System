function [lf,hf] = cfc_unpac(LF,HF,window,overlap)
% [pac] = cfc_pac(LF_sig,HF_sig,num_iter)
%  This function returns chunks of raw values corresponding to output of
%    cfc_pac
if  numel(LF)~=numel(HF)
    error('LF and HF must have the same length')
end

ncol = fix((numel(LF)-overlap)/(window-overlap));
colindex = 1 + (0:(ncol-1))*(window-overlap);
rowindex = (1:window)';
lf = NaN(window,ncol);
hf = NaN(window,ncol);
lf(:) = LF(rowindex(:,ones(1,ncol))+colindex(ones(window,1),:)-1);
hf(:) = HF(rowindex(:,ones(1,ncol))+colindex(ones(window,1),:)-1);

end



