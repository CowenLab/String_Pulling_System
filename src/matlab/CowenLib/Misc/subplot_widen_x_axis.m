function subplot_widen_x_axis(h,exp_x)
%
% Cowen 2017
exp_x = exp_x/length(h);
for ii = 1:length(h)
    p = get(h(ii),'Position');
    p(3) = p(3) + exp_x; % this makes the figures wider.
    set(h(ii), 'Position', p);
end

