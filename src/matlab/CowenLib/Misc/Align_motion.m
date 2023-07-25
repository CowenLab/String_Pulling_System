function OUT = Align_motion(T, range, speed);
% You know the velocity, but at another dt than at what you want and
% you want to assign speed to a differnt sized matrix.

% cowen Fri Apr 16 20:58:15 1999


OUT = zeros(size(T));
for ii = 1:(length(T))
  indexval = binsearch(range, T(ii));
  OUT(ii) = speed(indexval);
end
