function B = Is_int(I)
% INPUT: a vector of numbers
% OUTPUT: A boolean that tells if all of these numbers are integers(have
%         no values to the right of the decimal point.
%

% cowen

B = (sum(round(I(:))-I(:)))== 0;
