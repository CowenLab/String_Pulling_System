function axx = SPEC_plot_spectrogram_mvt_and_psd(SPEC,fq,x,baseline,markers, POS, cax, units, PSD_IX)
% Plot a 3-pane plot of position, PSD, and average power.
%  It can also handle event times.
if nargin < 7
    cax = [];
end
if nargin < 8
    units = 'std';
end
if nargin < 9
    PSD_IX = [];
end
axx(2) = axes('Position',[0.3,0.1,0.6,0.6]);

if ~isempty(baseline)
    SPEC = SPEC - repmat(baseline,size(SPEC,1),1);
end

SPEC_plot_spectrogram(SPEC,fq,x,baseline,markers)
if isempty(cax)
    cax = caxis;
else
    pc = prctile(SPEC(:),[2 98]);
    ccax(1) = min([pc(1) cax(1)]);
    ccax(2) = max([pc(2) cax(2)]);
    caxis(ccax)
end

ylabel('')
xlabel('Time (hours)')
a = axis(gca);
% PLOT POSITION
axx(1) = axes('Position',[0.3,0.71,0.6,0.15]);
% plot(POS(:,1),POS(:,2),'y','LineWidth',3)
hold on
plot(POS(:,1),POS(:,2),'k','LineWidth',1)
axis tight
aa = axis(gca);
aa(1:2) = a(1:2);
axis(aa);
set(gca,'XTickLabel','')
% set(gca,'XTick',axx(2).XTick)
box off
ylabel('Speed')
pubify_figure_axis

% PSD
axx(3) = axes('Position',[0.1,0.1,0.15,0.6]);
S2 = SPEC; mns = [];

if isempty(PSD_IX)
    mns = nanmean(S2);
else
    if iscell(PSD_IX)
        for ii = 1:length(PSD_IX)
            mns(ii,:) = nanmean(S2(PSD_IX{ii},:));
        end
    else
        mns(ii,:) = nanmean(S2(PSD_IX,:));
    end
end

% se = iqr(SPEC);
if Rows(mns) == 1
    clrs = [0 0 0 ];
else
%     clrs =  hot(Rows(mns)+4);
%      clrs = lines(Rows(mns));
     clrs = linspecer(Rows(mns));
end
lab = cell(Rows(mns),1);
for ii = 1:Rows(mns)
    plot(mns(ii,:),fq,'LineWidth',3,'Color',clrs(ii,:))
    hold on
    lab{ii} = num2str(ii);
end
legend(lab)
legend boxoff
% hold on 
% plot(mn+se/2,fq,'LineWidth',2,'Color','r')
% plot(mn-se,fq,'LineWidth',2,'Color','r')
axis tight
box off
ax(1) = min([min(mns(:)) cax(1)]);
ax(2) = max([max(mns(:)) cax(2)*.8]);

set(gca,'XLim',ax)
set(gca,'YLim',fq([1 end]))
plot_vert_line_at_zero
pubify_figure_axis
xlabel(units)
ylabel('Hz')
axes(axx(1));