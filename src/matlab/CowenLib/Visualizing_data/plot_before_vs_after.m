function OUT = plot_before_vs_after(x,Y1,Y2,titstr)
% Assumes that Y1 and Y2 are within-subject same number of trials.

dY = Y1-Y2;

figure
subplot(3,2,1);
imagesc(x,[],sort_matrix(Y1,'peak'))
cax = caxis;
colorbar
title(['Before ' titstr])
pubify_figure_axis


subplot(3,2,2);
imagesc(x,[],sort_matrix(Y2,'peak'))
caxis(cax);
colorbar
title('After')
pubify_figure_axis


subplot(3,2,3:4);
plot_confidence_intervals(x,Y1,[],[.2 .7 .2])
hold on
plot_confidence_intervals(x,Y2,[],[.7 .2 .2])
pubify_figure_axis


subplot(3,2,5:6);
pt= [];
psr = [];
for ii = 1:Cols(dY)
    psr(ii) = signtest(dY(:,ii));
    [~,pt(ii)] = ttest(dY(:,ii));
end
pix = pt < 0.01;
plot_confidence_intervals(x,dY,[],[0 0 0])
plot_horiz_line_at_zero
a = axis;
plot(x(pix),ones(1,sum(pix))*a(4),'r*')
xlabel('ms')
pubify_figure_axis
ylabel('Bef-Aft')


OUT.pt = pt;
OUT.psr = psr;

%%%%%%%%%%%%%%%
% figure
% plot_confidence_intervals(Dset.S(1).AutoCorr_x_ms,diff_ac(IXsel,:),[],GP.Colors.Selective)
% plot_confidence_intervals(Dset.S(1).AutoCorr_x_ms,diff_ac(IXnonsel,:),[],GP.Colors.NonSelective)
% plot_horiz_line_at_zero
% xlabel('ms')
% pubify_figure_axis
% legend_color_text({'Sel' 'Non Sel'},{GP.Colors.Selective GP.Colors.NonSelective});
% ylabel('Bef-Aft AC')
% title(titstr)
% UPSHOT: there appears 