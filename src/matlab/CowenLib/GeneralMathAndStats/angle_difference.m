function ang_diff = angle_difference(theta1,theta2,type)
% Compute the difference between 2 angles (theta1 and theta2)
% in degrees.
% THIS IS WEIRD
if nargin < 3
    type = 'degrees';
end
switch type
    case 'degrees'
        ang_diff = (mod(theta1 - theta2 + 180, 2*180) - 180);
    case 'radians'
        ang_diff = (mod(theta1 - theta2 + pi, 2*pi) - pi);
    otherwise
        error('wrong angle type: degrees or radians')
end