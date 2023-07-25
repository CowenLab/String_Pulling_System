function A = Align_tsds(tsa)
%function A = Align_tsds(tsa)
% 
% Create an array of tsds that have the exact same range of
% values. This corrects the fact that Restrict does not always create
% ranges of exactly the same value on different tsds. See tsd/Interp
% for another way to align tsds.
% 
%
% INPUT: 
%       tsa = array of ts or tsd or ctsd objects
%
% OUTPUT:
%     A     = a cell array of objects with exactly the same range. 
%
% cowen Fri Jul  2 17:05:41 1999

% make the lenght of A be equal to tsa.
A{length(tsa)} = [];
% Go through each element and restrict it to the times passed
for ii = 1:length(tsa)
  if ~isempty(tsa{ii})
    A{ii} = Restrict(tsa{ii}, stime, etime);
  end
end
