function OUT = SPG_plot_of_pull_behavior()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run this function in the data directory.
% Determine if paw tracking is correlating with IMU and POS
% This just analyzes behavior, not neural data.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
close all; fclose all; % ensure nothing else is open.
OUT = [];
PLOT_IT = true;
CONV_TO_CM = true;
fig_pos = [40 40 1130 800];

GP = SPG_Globals;
SES = SPG_Session_Info();
OUT.aborted = false;

OUT.SES = SES;
%% Load Data %%
out_dir = fullfile(SES.Session_dir,'behavior_figs_and_vids');
if ~exist(out_dir,'dir')
    mkdir(out_dir)
end
if ~exist(fullfile(SES.Front_cam_dir,'Front_Cam_Pos.mat'),'file') || isempty(SES.Raw_videos_front_fname)
    OUT.aborted = true;
    pwd
    disp('Could not find a Front Cam Pos Mat file. Aborted this session.')
    return
end
% Process and plot the data.
[FCam,FCamInfo] = SPG_Load_and_Clean_DLC_Front_Camera_Tracking(fullfile(SES.Front_cam_dir,'Front_Cam_Pos.mat'));
SPG_plot_segmented_paw_position(FCam);
SPG_plot_polar_plot_of_paw_position(FCam);


% TCam = load(fullfile(SES.Top_cam_dir,'Top_Cam_Pos.mat'),'POS');
IMU = SPG_Load_and_Process_IMU(fullfile(SES.Intan_rec_dir,'Inertial_data.mat'));
load(fullfile(SES.Intan_rec_dir,'EVT.mat'),'EVT');
E = SPG_Load_Events_From_Excel(SES.Event_times_file);
% Extract rotary encoder speed from the EVT timestamps...
ROT = SPG_Rotary_Encode_Speed();
if PLOT_IT
    % to validate the rotation episodes, plot
    SPG_Rotary_Encode_Speed()
end
% [PAW2,EVENTS] = SPG_process_paw_data(FCam,
% ROT.good_string_pull_intervals_uSec) % does not work yet.

% For each bout, find the appropriate indices in the data...
IX_fcam = []; IX_tcam = []; IX_IMU = []; IX_ROT = [];
% invervals_uS = ROT.good_string_pull_intervals_uSec;
invervals_uS = FCamInfo.good_pull_intervals_uSec;
for iB = 1:Rows(invervals_uS)
    sted = invervals_uS(iB,1:2);
    IX_fcam{iB} = FCam.Intan_uS >= sted(1) & FCam.Intan_uS <= sted(2);
    %     IX_tcam{iB} = TCam.Intan_uS >= sted(1) & TCam.Intan_uS <= sted(2);
    IX_IMU{iB} = IMU.t_uS >= sted(1) & IMU.t_uS <= sted(2);
    IX_ROT{iB} = ROT.t_uSec >= sted(1) & ROT.t_uSec <= sted(2);
end
%
durs = invervals_uS(:,2) - invervals_uS(:,1);
figure(101)
set(gcf,'Position',fig_pos)
for iB = 1:Rows(invervals_uS)
% for iB = 24:24
    t_imu_sec =IMU.t_uS(IX_IMU{iB})/1e6;
    t_imu_sec = t_imu_sec - t_imu_sec(1);
    t_rot_sec = ROT.t_uSec(IX_ROT{iB})/1e6;
    t_rot_sec = t_rot_sec -  t_rot_sec(1);    
    t_cam_sec = FCam.Intan_uS(IX_fcam{iB})/1e6;
    t_cam_sec = t_cam_sec -  t_cam_sec(1);

    LX = FCam.Left_Paw_x(IX_fcam{iB})*-1;
    LY = FCam.Left_Paw_y_flipped(IX_fcam{iB});
    RX = FCam.Right_Paw_x(IX_fcam{iB})*-1;
    RY = FCam.Right_Paw_y_flipped(IX_fcam{iB});
    NX = FCam.Nose_x(IX_fcam{iB})*-1;
    NY = FCam.Nose_y_flipped(IX_fcam{iB});
    pos_lab = 'pixels'
    if CONV_TO_CM
        LX = LX*GP.front_cm_per_pixel;
        LY = LY*GP.front_cm_per_pixel;
        RX = RX*GP.front_cm_per_pixel;
        RY = RY*GP.front_cm_per_pixel;
        NX = NX*GP.front_cm_per_pixel;
        NY = NY*GP.front_cm_per_pixel;
        pos_lab = 'cm';
    end


    clf
    subplot(3,4,9:12)
    % plot an overview of all the rotary encoder movement.
    ix = find(ROT.Speed > 50,1,'first'):find(ROT.Speed > 50,1,'last');
    ix(1) = ix(1)-20;
    ix(2) = ix(2)+20;
    plot(ROT.t_uSec(ix)/60e6, ROT.Speed(ix),'b.')
    hold on
    plot(ROT.t_uSec(IX_ROT{iB})/60e6, ROT.Speed( IX_ROT{iB}),'r.')
    axis tight
    ylabel('Speed'); xlabel('minutes')
    pubify_figure_axis

    subplot(3,4,[1 2 5 6])
    mk = 2;
    plot(NX, NY,'o','color',GP.Colors.Nose,'MarkerSize',mk)
    hold on
    plot(LX, LY,'o','color',GP.Colors.LeftPaw,'MarkerSize',mk)
    plot(RX, RY,'o','color',GP.Colors.RightPaw,'MarkerSize',mk)
    title(sprintf('%s Bout %d',strrep(SES.title_str,'_',' '),iB))
    axis tight
%     axis equal
    legend('Nose','LeftP','RightP','Location','southwest'); legend boxoff
    pubify_figure_axis
    xlabel(pos_lab);ylabel(pos_lab)

    subplot(3,4,3:4)
    %     plot(t_imu_sec , IMU.speed_pc1(IX_IMU{iB}),'.-','color',GP.Colors.IMU,'MarkerSize',mk)
    %     hold on
    %     plot(t_imu_sec, IMU.absjerk(IX_IMU{iB}),'.-','color',GP.Colors.IMU*.5,'MarkerSize',mk)
    %     ylabel('IMU')
    %     legend('SpeedPC','AbsJerkPC'); legend boxoff
    plot(t_rot_sec, ROT.Speed( IX_ROT{iB}),'.-r','LineWidth',3)
    ylabel('Rot Spd')
    axis tight
    title('String Speed')
    pubify_figure_axis
    xlabel('sec')
    subplot(3,4,7:8)

    shift = max(LX) - min(LY);

    plot(t_cam_sec, LX-shift,'-','color',GP.Colors.LeftPaw*.8,'LineWidth',3)
    hold on
    plot(t_cam_sec, LY,'-','color',GP.Colors.LeftPaw,'LineWidth',3)

    plot(t_cam_sec, RX-shift,'-','color',GP.Colors.RightPaw *.8,'LineWidth',3)
    plot(t_cam_sec, RY,'-','color',GP.Colors.RightPaw,'LineWidth',3)
    axis tight
    ylabel(pos_lab);xlabel('sec')
    title('Paw Position')
    pubify_figure_axis
    xlabel('sec')
    % SVG used to import into ppt fine, but now it causes ppt to hang
    % I was able to import the svg into inkscape and was able to ungroup
    % but then importing into matlab required saving as a simple svg. It
    % imported, but ungrouping was still VERY slow.
    % exproting emf - was also a problem as it still would not allow
    % ungrouping in ppt.
    % UGH: finally - copy and past from illustrator did seem to finally
    % work!! Jeezuz - UGH - not now. Ungrouping seemst to cause ppt to
    % hang. 
    %
    % emf seems to cause ppt to hang.
    % PDF pixelated.
    % 
%     saveas(gcf,fullfile(out_dir,sprintf('plot_behavior_%s_bout_%d.png',SES.title_str,iB)))
end
% If you want the video, then run SPG_video_of_pull_behavior in this
% folder.
% SPG_video_of_pull_behavior();



