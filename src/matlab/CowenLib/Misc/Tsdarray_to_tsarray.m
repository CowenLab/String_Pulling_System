function tsarray = Tsdarray_to_tsarray(IN)
% INPUT
%   an array of tsd objects
% OUTPUT
%   an array of ts objects with just the range of the IN object
%

% cowen 2/10/00

for ii = 1:length(IN)
  tsarray{ii} = ts(Range(IN{ii},'ts'));
end
