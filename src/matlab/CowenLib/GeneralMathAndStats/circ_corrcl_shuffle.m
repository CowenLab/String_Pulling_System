function [rho, pval, z, v] = circ_corrcl_shuffle(alpha, x, n_shuff)
% Create a shuffle control for the correlation.
[rho, pval] = circ_corrcl(alpha, x);
if nargout > 2
    if nargin < 3
        n_shuff = 200;
    end
    v = zeros(n_shuff,1);
    len = length(alpha);
    for ii = 1:n_shuff
        v(ii) = circ_corrcl(alpha(randperm(len)), x);
    end
    z = (rho-mean(v))/std(v);
%     figure
%     histogram(v)
%     hold on
%     plot_vert_line_at_zero(rho);
%     title(sprintf('p %f z %d', pval, z))
end

