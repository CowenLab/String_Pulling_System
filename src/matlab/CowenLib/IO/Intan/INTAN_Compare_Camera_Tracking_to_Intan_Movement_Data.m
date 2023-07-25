function [OUT] = INTAN_Compare_Camera_Tracking_to_Intan_Movement_Data(intan_data_dir, POS_file_path)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This needs more metrics and plotting
% Should add string pulling.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT
%
% OUTPUT:
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine variable names.
% PLOT_IT = true;
% % this is the thresh for determining disgcontiguous time blocks.
% thresh_uS = 1e6/20; % let's say 1/20th of a second. Should cover the
%                     % resolution of the front and top camera.
% Extract_varargin;
clrs = lines(10);
% Load the events 
load(fullfile(intan_data_dir,'EVT.mat'),'EVT')
% Load the IMU
load(fullfile(intan_data_dir,'Inertial_data'))
% If there is string pulling data, then convert this to
ROT = String_pull_speed_from_event_times(EVT.rotary_encoder_uS);
[~,sc_imu] = pca(IMU.data_V);
sc_imu_spd = [0; abs(diff(sc_imu(:,1)))];
% Load the video data
load(POS_file_path)


u_body = unique(POS_info.body_part);
% plot the pos data ignoring time just to check
figure
for iB = 1:length(u_body)
    GIX = POS.([u_body{iB} '_likelihood']) > .6;
    subplot(1,4,1)
    plot(POS.([u_body{iB} '_x'])(GIX),POS.([u_body{iB} '_y'])(GIX),'.','MarkerSize',1,'Color',clrs(iB,:))
    hold on
    subplot(1,4,2:4)
    plot(POS.Intan_uS(GIX), POS.([u_body{iB} '_x'])(GIX),'.','MarkerSize',1,'Color',clrs(iB,:))
    plot(POS.Intan_uS(GIX), POS.([u_body{iB} '_y'])(GIX),'.','MarkerSize',1,'Color',clrs(iB,:))
    hold on
end
subplot(1,4,2:4)
yyaxis right
plot(IMU.t_uS, Z_scores(sc_imu(:,1)),'b-')
ylabel('IMU PC1 z')
yyaxis right
plot(IMU.t_uS, Z_scores(sc_imu_spd),'r-')
ylabel('IMU PC1 speed z')
title(POS_info.camera_name)

% Create an integrated measure of position (PCA) and plot this against the
% IMU and string pulling data.
PDATA = [];
for iB = 1:length(u_body)
    GIX = POS.([u_body{iB} '_likelihood']) > .6;
    P = [POS.([u_body{iB} '_x']) POS.([u_body{iB} '_y'])];
    P(~GIX,:) = nan;
    PDATA = [PDATA P];
end
[~, sc_vid, ~] = pca(PDATA);
% For comparison to the IMU, we really need a measure of the change of
% motion, not the xy location.
sc_vid_spd = [0; abs(diff(sc_vid(:,1)))];

figure
plot(POS.Intan_uS,Z_scores(sc_vid_spd))
hold on
plot(IMU.t_uS, Z_scores(sc_imu(:,1)))
plot(IMU.t_uS, Z_scores(sc_imu_spd))
if ~isempty(ROT)
    plot(ROT.t_uSec, Z_scores(ROT.Speed),'m')
end
ylabel('z')
legend('vid spd','imu pc1','imu spd','rot spd')
title(POS_info.camera_name)

% Find the IMU times that best correspond to the camera times and then do
% a scatterplot and stuff.
good_times_IX = ~isnan(sc_vid(:,1));
ptime = POS.Intan_uS(good_times_IX);
new_IMU = interp1(IMU.t_uS, sc_imu(:,1),ptime);
new_IMU_spd = interp1(IMU.t_uS, sc_imu_spd,ptime);

figure
plot(ptime, new_IMU)
hold on

ylabel('pc1 IMU')

yyaxis right
plot(ptime, Z_scores(sc_imu(good_times_IX,1)),'b-')
hold on
plot(ptime, Z_scores(sc_imu_spd(good_times_IX,1)),'r-')
if ~isempty(ROT)
    hold on
    plot(ROT.t_uSec, Z_scores(ROT.Speed),'m-')
    ylabel('pc1 VIDEO and rotary enc.')
else
    ylabel('pc1 VIDEO')
end

corr(new_IMU,sc_vid(good_times_IX,1),'Rows','complete','Type','Spearman')
corr(new_IMU,sc_vid_spd(good_times_IX),'Rows','complete','Type','Spearman')
corr(new_IMU_spd,sc_vid_spd(good_times_IX),'Rows','complete','Type','Spearman')
corr(new_IMU_spd,sc_vid(good_times_IX,1),'Rows','complete','Type','Spearman')
figure
subplot(1,2,1)
plot(new_IMU,sc_vid_spd(good_times_IX),'.')
lsline
xlabel('IMU'); ylabel('vid |pc1| speed')
subplot(1,2,2)
plot(new_IMU_spd,sc_vid_spd(good_times_IX),'.')
lsline
xlabel('IMU Speed'); ylabel('vid |pc1| speed')

