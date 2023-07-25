function e = envelope_cowen(D,method)
% Returns the envelope (connecting the  peaks of (max(abs(D))))
% INPUT (data), method (default = connect peaks.
%
% There is also a matlab envelope function.
% Cowen (2014) - got rid of NANs
if nargin < 2
    method = 'default';
end

transpose_it = false;
if size(D,1) == 1
    D = D';
    transpose_it = true;
end
if size(D,2) > 1
    e = [];
    for iC = 1:size(D,2)
        e(:,iC) = envelope_cowen(D(:,iC),method);
    end
    return
end

switch method
    case 'default'
        D = abs(D);
        PeaksIdx  = find([diff(D); 0] < 0 & [0; diff(D)] > 0);
        if isempty(PeaksIdx)
            e = nan(length(D),1);
        else
            e = interp1(PeaksIdx,D(PeaksIdx),[1:length(D)]');
            IX = isnan(e); % replace the nan's from interp with original data.
            e(IX) = D(IX);
            
            if transpose_it
                e =e';
            end
            
            if nargout == 0
                plot(1:length(D),D,'b',PeaksIdx,ones(size(PeaksIdx)),'r.')
                hold on
                plot(1:length(e),e,'g')
            end
        end
    case 'hilbert'
        % From Muthukumaraswamy et al 2015
        e = abs(hilbert(D));
        if transpose_it
            e =e';
        end
end
