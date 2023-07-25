function st_ed_ix = find_intervals_logical(IX)
% Finds start and end INDICES of the false or zero valus of the logical
% indices.
% cowen
% IX = [0 0 1 1 0 0 1 1 1 0 1 0 ];
% IX = [1 0 0 1 1 ];
v = double(IX);
v(end+1) = 0; % forces an end if there is an end that is high.
t = 1:(length(v));
st_ed_ix = find_intervals([t(:) v(:)],.5);

st_ed_ix(:,1) = st_ed_ix(:,1)+1;