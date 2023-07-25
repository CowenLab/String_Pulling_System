function h = imagesc_by_group(x,M,g, varargin)
group_IDs = unique(g); % determines the sort order.
plot_SEM = true;
title_text = '';
x_text = '';

Extract_varargin
IX = false(Rows(M),length(group_IDs));
sorted_M = [];

for iG = 1:length(group_IDs)
    IX(:,iG) = g(:) == group_IDs(iG);
    small_M = M(IX(:,iG),:);
    sorted_M = [sorted_M; small_M];
    mn(iG,:) = mean(small_M,'omitnan');
    se(iG,:) = Sem(small_M);
    
end
s = cumsum(sum(IX));
s = s(1:end-1);

h(1) = subplot(3,1,1:2);
imagesc(x,[],sorted_M)
pubify_figure_axis
hold on
plot(x(1)*ones(size(s)),s,'r>')
colorbar_label
title(title_text)


h(2) = subplot(3,1,3);
plot(x,mn, 'LineWidth',2)
legend(group_IDs,'AutoUpdate','off')
legend boxoff

if plot_SEM
    hold on
    plot(x,mn+se,'r:')
end

axis tight;
pubify_figure_axis
xlabel(x_text)

% subplot(h(1))
