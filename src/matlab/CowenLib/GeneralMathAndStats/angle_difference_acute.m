function ang_diff = angle_difference_acute(theta1,theta2,type)
% Compute the difference between 2 angles (theta1 and theta2)
% in degrees.
% THIS IS WEIRD
if nargin < 3
    type = 'degrees';
end
if nargin == 1
    ang_diff = theta1;
else
    ang_diff = theta1-theta2;
end
switch type
    case 'degrees'
        IX = ang_diff > 180;
        ang_diff(IX) = ang_diff(IX) - 360;
        IX = ang_diff < -180;
        ang_diff(IX) = ang_diff(IX) + 360;
        
    case 'radians'
        IX = ang_diff > pi;
        ang_diff(IX) = ang_diff(IX) - 2*pi;
        IX = ang_diff < -pi;
        ang_diff(IX) = ang_diff(IX) + 2*pi;
    otherwise
        error('wrong angle type: degrees or radians')
end