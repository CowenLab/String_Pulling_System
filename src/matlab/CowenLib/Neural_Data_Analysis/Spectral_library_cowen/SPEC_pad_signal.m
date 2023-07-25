function [padsig,GIX] = SPEC_pad_signal(sig,npts_to_pad,pad_type,pad_spec)
% Pads the BEGINNING AND END of a signal with values specified 
% returns the indices of the 'Good' portion, making it easy to extract the
% original un-padded region later on.
% 
% Cowen 2020
if size(sig,2) == 1
    error('Pass in a row vector')
end
if nargin < 4
    pad_spec = 0;
end
if nargin < 3
    pad_type = 'zeros';
end
GIX = true(1,length(sig) + 2*npts_to_pad);
GIX(1:npts_to_pad) = false;
GIX(end-npts_to_pad+1:end) = false;
% sum(GIX)
% length(sig)

switch pad_type
    case 'zeros'
       pd = ones(1,npts_to_pad)*pad_spec;
       padsig = [pd sig pd];
    case 'flipdata'
       % flips the data on the front and end and appends it to the signal.
       flipfront = sig(npts_to_pad+1:-1:2); 
       flipend = sig(end-1:-1:end-npts_to_pad); 
       padsig = [flipfront sig flipend];
end

sigix = npts_to_pad+1:((npts_to_pad+1)+length(sig)-1);
if nargout == 0
    figure
    plot(1:length(padsig),padsig,'.-',sigix,sig,'.-')
end