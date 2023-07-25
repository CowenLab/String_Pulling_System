function Sf = CID_SpikeSampleFreq(CID)
% Return the sample frequency for the specified cell.
% cowen (2006)
Sf = zeros(length(CID),1);
for ii = 1:length(CID)
    [C] = Cell_ID(CID(ii));
    if C(1) == 7885 | (C(1) == 7998 & C(2) <= 76 )
        Sf(ii) = 25653;
    elseif C(1) == 7998 & C(2) > 76
        Sf(ii) = 30065 ;
    elseif C(1) == 8124
        Sf(ii) = 30120;
    else
        error('Unknown CID')
    end
end
