function O = Find_on_same_tetrode_in_R(tet_id)
%
% Find indices in the cell by cell R matrix that indicate where cells
% on the same tetrode reside so that these correlations can be
% eliminated later.
%
% INPUT: A list whose index indicates cell id and whose value
% indicates the tetrode number.
%
% OUTPUT: Indices(not rows and columns) of the locations in the R
% matrix where the cells reside.
% 
% see Assign_tet_numbers
%
%function O = Find_on_same_tetrode_in_R(tet_id)


tet_id = tet_id(:);

st_ends = find(diff([999; tet_id ;999])~=0);

M = zeros(length(tet_id));

for ii = 1:length(st_ends)-1
  M(st_ends(ii):(st_ends(ii+1)-1),st_ends(ii):(st_ends(ii+1)-1)) = inf;
end
O = find(isinf(M));
