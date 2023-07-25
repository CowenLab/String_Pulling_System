function q = Quantize(in, n_quanta)
% Given a vector or tsd object, quantize it by Q factor
%
% INPUT:
%
% OUTPUT:

switch class(in)
  case {'tsd' 'ts'}
    D = Data(in);
  otherwise
    D = in;
end

mn = min(D);
mx = max(D);
D = D - mn;
difference = mx -mn;
O = round(D/(difference/(n_quanta-1)));


switch class(in)
   case 'tsd' 
      q = ts(O);
   case 'ts'
      q = tsd(Range(in,'ts'),O);
   otherwise
      q = O;
end

