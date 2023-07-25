function TCout = Normalize_TC(TCin, Occ)
%function TCout = Normalize_TC(TCin, Occ)
%
%  INPUT
%      cell array of tuningcurves or single TC matrix 
%      occupancy matrix
%
%  OUTPUT
%      normailized tuningcurves (TC./Occ). If input was a cell array
%      then the output will be a cell array. Else, it will be a matrix.

%      NOTE: All NaNs are changed to zero
%
% cowen Fri Apr 16 16:06:13 1999

if ~iscell(TCin)
  TC{1} = TCin;
  not_cell = 1;
else
  TC = TCin;
  not_cell = 0;
end

for ii = 1:length(TC)
    % WARNING: ADDING EPS DOES STRANGE THINGS!!! DO NOT USE IT.
  TC1{ii} = TC{ii}./Occ;
  % Change all the NaNs to zero.
  TC1{ii}(find(isnan(TC1{ii}))) = 0;
end

if not_cell
  TCout = TC1{1};
else
  TCout = TC1;
end
