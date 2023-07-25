function subplot_widen_y_axis(h,exp_x)
exp_x = exp_x/length(h);
for ii = 1:length(h)
    p = get(h(ii),'Position');
    p(4) = p(4) + exp_x; % this makes the figures wider.
    set(h(ii), 'Position', p);
end

