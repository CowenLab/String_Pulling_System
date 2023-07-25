function SPEC_plot_spectrogram(SPEC,fq,x,baseline,markers, units)
if nargin < 4
    baseline = [];
end
if nargin < 5
    markers = [];
end
if nargin < 6
    units = [];
end

if ~isempty(baseline)
    if isstr(baseline)
        if strcmpi(baseline,'z')
        end
    else
        SPEC = SPEC - repmat(baseline,size(SPEC,1),1);
    end
end
imagesc(x(:),fq(:),SPEC');
hold on
axis xy
ylabel('Hz')
if ~isempty(markers)
    for ii = 1:length(markers)
        a = axis;
        plot([markers(ii) markers(ii) ],a(3:4),'w','LineWidth',3)
        plot([markers(ii) markers(ii) ],a(3:4),'k:','LineWidth',3)
    end
end
% if ~isempty(POS)
%     ax_pos = get(gca,'Position');
%     ax = axes('Position',ax_pos);
%     plot(POS(:,1),POS(:,2),'w','LineWidth',3)
%     hold on
%     plot(POS(:,1),POS(:,2),'g','LineWidth',1)
%     ax.Color = 'none';
%     ax.YAxisLocation = 'right';
% %     ax.XAxis = 'off';
%     ax.XTickLabel = '';
%     axis tight
%     ax.YTick
%     
% end

colorbar_label(units)
colormap(jet)
pubify_figure_axis
