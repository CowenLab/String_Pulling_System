function [cors] = Optimize_bin_smoothing_parameters(X,y,param_vals,smooth_fun)
% X is a multi-dimensional input
% y is the parameter to maximize the r-squred
% smooth_type is the smoothing kernel type.
% param values are the window-sizes to test.
if nargin < 4
    smooth_fun = @hamming;
end
% param_vals= 0 means do no smoothing at all.
% trls = 1:Rows(X);

for ii = 1:length(param_vals)
    if ~param_vals(ii) == 0
        knl = smooth_fun(param_vals);
        X = convn(X,knl,'same');
        r = corr(X,y,'Spearmans');
    end
end

