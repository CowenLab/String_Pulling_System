function Ptsd = Smooth_tsd(Atsd, windowsize)
% Smooths the position data.
%
% INPUT: A tsd and an optional parameter to set the level of smoothing
%
% OUTPUT: A smoothed tsd
%

% cowen Fri Apr 16 16:38:09 1999
if nargin == 1
  windowsize = 10; % The default
end
D = Data(Atsd);
R = Range(Atsd, 'ts');
SD = Smooth_vel(D,windowsize);
Ptsd = tsd(R,SD);