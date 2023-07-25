function output = Decimal_2_byte_conversion_for_Maestro(input)
% Only uses 7 bit "bytes"
by = dec2bin(input);
byst1 = by(end-6:end);
byst2 = by(1:end-7);
output(1) = bin2dec(byst2);
output(2) = bin2dec(byst1);
%  bin2dec('101110 1110000')
% 
% ans =
% 
%         6000
% 1011101110000
% dec2bin(46)
% 
% ans =
% 
% 101110
% dec2bin(112)
% 
% ans =
% 
% 1110000