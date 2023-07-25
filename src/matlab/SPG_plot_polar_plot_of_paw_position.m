function OUT = SPG_plot_polar_plot_of_paw_position(FCam)
% GP = SPG_Globals;
OUT = [];
if nargin == 0
    SES = SPG_Session_Info();
    [FCam] = SPG_Load_and_Clean_DLC_Front_Camera_Tracking(fullfile(SES.Front_cam_dir,'Front_Cam_Pos.mat'));
end

FIX = FCam.PullPhaseLeft ~= 'uncategorized' & FCam.PullPhaseRight ~= 'uncategorized';
frames_ix = find(FIX);
% cats = GP.phase_codes2;
% colors = lines(length(cats));
%%
x = FCam.Left_Paw_Cyc_norm_x(frames_ix);
y = FCam.Left_Paw_Cyc_norm_y(frames_ix)*-1;
ph = FCam.Left_Paw_phase(frames_ix);
sp = FCam.Left_Paw_speed(frames_ix);
gp = FCam.PullPhaseLeft(frames_ix);
rlim = prctile(sp,99);
rlim = mean(rlim);

figure
subplot(2,2,2)
gscatter(x,y,gp);
title('Left')
% axis equal
axis tight
pubify_figure_axis
% legend off
subplot(2,2,4)
gpolarplot(ph,sp,gp);
axis tight
set(gca,'RTickLabel','')
set(gca,'RLim',[0 rlim])
set(gca,'ThetaZeroLocation','bottom')

x = FCam.Right_Paw_Cyc_norm_x(frames_ix);
y = FCam.Right_Paw_Cyc_norm_y(frames_ix)*-1;
ph = FCam.Right_Paw_phase(frames_ix);
sp = FCam.Right_Paw_speed(frames_ix);
gp = FCam.PullPhaseRight(frames_ix);
rlim = prctile(sp,99);
rlim = mean(rlim);

subplot(2,2,1)
gscatter(x,y,gp);
title('Right')
axis tight
pubify_figure_axis
% legend off
subplot(2,2,3)
gpolarplot(ph,sp,gp);
axis tight
set(gca,'RTickLabel','')
set(gca,'RLim',[0 rlim])
set(gca,'ThetaZeroLocation','bottom')

set(gcf,'Position',[209    73   967   781])
