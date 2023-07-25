function Save_figs(fig_nos,name,save_type)
% Default is 'jpeg', 'fig' also works.
if nargin < 3
    save_type = 'jpeg';
end

for ii = fig_nos
    figure(ii)
    saveas(gcf,[name '_' num2str(ii)],save_type)
end
