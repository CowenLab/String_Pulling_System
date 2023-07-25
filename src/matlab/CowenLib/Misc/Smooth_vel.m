function smoothvel = Smooth_vel(v, winlength)

%  smoothvel = SmoothVel(v, winlength)
% 
% INPUT: 
%     vector of velocities(it can be the diff on the x or y
%     position data.
%
%     winlength: the smoothing factor.
% 
% NOTE: A good winlength for maze seems to be 10

% cowen Fri Apr 16 15:56:59 1999

smoothvel = conv(v, hamming(winlength));

if mod(winlength, 2) ~= 0
  s1 = floor(winlength / 2);
  s2 = s1 + 1;
else
  s1 = winlength / 2;
  s2 = s1;
end

smoothvel = smoothvel(s1:end-s2);








