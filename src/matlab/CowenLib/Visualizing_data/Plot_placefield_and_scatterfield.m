function [PF,SC]=Plot_placefield_and_scatterfield(t,POS,n_2D_bins,trial_times,smooth_factor)
if nargin < 3
    n_2D_bins = 50;
end
if nargin < 4
    trial_times = [];
end
if nargin < 5
    smooth_factor = [];
end

%[SFx, SFy] = ScatterFields(t, tsd(POS(:,1),POS(:,2)), tsd(POS(:,1),POS(:,3)));
%SC = [Data(SFx{1}) Data(SFy{1})];
% Use cowen - faster
SC = ScatterFields_cowen(POS,t);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(2,1,1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%            axes('position',[.55 .55 .4 .35])
plot(POS(:,2),POS(:,3),'.','Color',[0.85 0.85 0.85] )
hold on
% plot(ScatField(ScatField_ix,2),ScatField(ScatField_ix,3),'r.','MarkerSize',8)

plot(SC(:,2),SC(:,3),'k.','MarkerSize',8)
axis tight;axis square
%axis off
set(gca,'XTickLabel',[])
set(gca,'YTickLabel',[])
box off
axis off
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(2,1,2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(trial_times)
    PF= Plot_placefield(t,POS,[],n_2D_bins,smooth_factor,1);
else
    PF= Plot_placefield_by_trial(t,POS,trial_times,n_2D_bins,smooth_factor);%,plot_it)
end
colormap(jet2)
axis square
axis off
