function [cfs,f,A] = cwt_fix(cfs,f,desired_f)
% Fixes the wonky output of cwt. Returns data in standard increasing
% frequency format and column form (each col is a frequency).
% Cowen 2018;
if nargin < 3
    desired_f = [];
end
cfs = abs(cfs);
cfs = cfs(end:-1:1,:);
f = f(end:-1:1);

if nargout > 2
    A = angle(cfs);
    if ~isempty(desired_f)
        A = interp1(f,A,desired_f)';
    end
end

if ~isempty(desired_f)
    cfs = interp1(f,cfs,desired_f)';
end