function CI = confidence_intervals(varargin);
% superceded by ci
% cowen
%disp('Superceded by conf_int')
[mn ci] = conf_int(varargin{:});
CI = [ci(1,:);mn;ci(2,:)];
