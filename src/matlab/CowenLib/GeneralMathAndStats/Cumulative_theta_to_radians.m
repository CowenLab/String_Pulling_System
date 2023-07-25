function th = Cumulative_theta_to_radians(cth)
% Converts positive theta to radians. Does not work for negative values of
% theta.
th = cth - floor(cth/(2*pi))*2*pi;
       