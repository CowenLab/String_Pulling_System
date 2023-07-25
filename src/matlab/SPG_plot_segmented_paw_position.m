function p = SPG_plot_segmented_paw_position(POS)
%% INPUT: PAW = 7 column table with xy of paw per unit time.
% Find segmented times.
if nargin == 0
    SES = SPG_Session_Info();
    [POS] = SPG_Load_and_Clean_DLC_Front_Camera_Tracking(fullfile(SES.Front_cam_dir,'Front_Cam_Pos.mat'));

end

GP = SPG_Globals;
GIXl = POS.PullPhaseLeft ~= 'uncategorized';
GIXr = POS.PullPhaseRight ~= 'uncategorized';

% [GIX,GIXl,GIXr,INF] = LK_process_paw_data(PAW, good_string_pull_intervals_uSec);
% plot the categorized trajectories - un-normalzied
figure
subplot(1,8,1:4)
gscatter( POS.Left_Paw_x(GIXl)-300,  POS.Left_Paw_y(GIXl)*-1, POS.PullPhaseLeft(GIXl))
hold on
gscatter( POS.Right_Paw_x(GIXr),  POS.Right_Paw_y(GIXr)*-1, POS.PullPhaseRight(GIXr))
title('Left and Right Paw')
pubify_figure_axis
axis tight
xlabel('pixel'); ylabel('pixel')
% normalize each trajectory by the pull interval
subplot(1,8,5:8)
gscatter( POS.Left_Paw_Cyc_norm_x(GIXl)-300,  POS.Left_Paw_Cyc_norm_y(GIXl)*-1, POS.PullPhaseLeft(GIXl))
hold on
gscatter( POS.Right_Paw_Cyc_norm_x(GIXr),  POS.Right_Paw_Cyc_norm_y(GIXr)*-1, POS.PullPhaseRight(GIXr))
title('Norm Left and Right Paw')
pubify_figure_axis
axis tight
xlabel('pixel');ylabel('pixel')
set(gcf,'Position',[ 10  10 1600 744])

