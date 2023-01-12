function [MT,revised_string_pull_intervals_uSec, PAW, ROT, POS, IMU, EVENTS] = LK_Combine_All_String_Pull_Motion_To_Table(Behavior_sFreq,PLOT_IT)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Cowen 2020.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
GP = LK_Globals;
if nargin < 2
    PLOT_IT = false;
end
if ~exist(GP.fnames.string_pull_intervals_file,'file')
    LK_Determine_good_pull_bouts()
end
load('Filtered_Time_Stamped_Coordinates_Corrected_Ori.mat');
MT = [];
vbls = {'Left_x' 'Left_y' 'Right_x' 'Right_y' 'Nose_x' 'Nose_y' 'Left_speed' 'Right_speed'  'Left_acc' 'Right_acc' 'Nose_speed' 'Right_x_to_nose' 'Right_y_to_nose' 'Left_x_to_nose' 'Left_y_to_nose' 'Left_dist_to_nose' 'Right_dist_to_nose'  'Right_y_d1' 'Left_y_d1'};
load(GP.fnames.meta_file,'META')
load(GP.fnames.event_file,'EVT')
load(GP.fnames.string_pull_intervals_file,'good_string_pull_intervals_uSec')
% Add a little buffer at the start and end of each interval to get some
% padding...
good_string_pull_intervals_uSec(:,1) = good_string_pull_intervals_uSec(:,1) - 2e6;
good_string_pull_intervals_uSec(:,2) = good_string_pull_intervals_uSec(:,2) + 2e6;

% Load and process the paw data from DeepLabCut 
% [PAW] = LK_process_paw_data(GP.fnames.paw_file, good_string_pull_intervals_uSec);
[PAW, EVENTS] = LK_process_paw_data(T3, good_string_pull_intervals_uSec);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load inertial, top-down tracker, rotary encoder and calculate string pull rate.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMU
%%%%%%%%%%%%%
IMU = LK_Load_and_Process_IMU(GP.fnames.imu_file);
[~,IMU.GIX] = Restrict(IMU.t_uS,good_string_pull_intervals_uSec);
load(GP.fnames.pos_file,'POS')
%%%%%%%%%%%%%
% POS (top down)
%%%%%%%%%%%%%
[~,POS.GIX] = Restrict(POS.Time_uS,good_string_pull_intervals_uSec);
% Determine good tracking color.
if sum(sum(POS.Green_xy)) < 10
    POS.COM_xy = POS.Red_xy;
    POS.Speed = POS.Speed_Red;
else
    POS.COM_xy = POS.Green_xy;
    POS.Speed = POS.Speed_Green;
end

%%%%%%%%%%%%%
% Rotary Encoder
%%%%%%%%%%%%%
ROT = LK_Rotary_Encode_Speed(EVT, META);
PULL = LK_Determine_Individual_Pull_Times(ROT,good_string_pull_intervals_uSec);
% Determine the start and end of the string pulling period.
[~,ROT.GIX] = Restrict(ROT.t_uSec,good_string_pull_intervals_uSec);

% move_intervals_uSec = find_intervals([ROT.t_uSec(ROT.GIX) ROT.Speed(ROT.GIX) > 4 & ROT.Speed(ROT.GIX) < 300],.5);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create a useful table that has all of the behavioral variables in ONE
% place and in the same timescale.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t_uSec = good_string_pull_intervals_uSec(1):1e6/Behavior_sFreq:good_string_pull_intervals_uSec(end);
t_uSec = t_uSec(:);
%% This is the container that will hold all of the position data.
MT = table(t_uSec);
for iV = 1:length(vbls)
    % MT.Left_x = interp1(PAW.Time_uSec(PW.GIXl), PAW.Left_x(PW.GIXl),MT.t_uSec);
    if contains(vbls{iV},'Left')
        MT.(vbls{iV}) = interp1(PAW.Time_uSec(PAW.GIXl), PAW.(vbls{iV})(PAW.GIXl),MT.t_uSec);
    elseif contains(vbls{iV},'Right')
        MT.(vbls{iV}) = interp1(PAW.Time_uSec(PAW.GIXr), PAW.(vbls{iV})(PAW.GIXr),MT.t_uSec);
    elseif contains(vbls{iV},'Nose')
        MT.(vbls{iV}) = interp1(PAW.Time_uSec, PAW.(vbls{iV}),MT.t_uSec);
    else
        MT.(vbls{iV}) = interp1(PAW.Time_uSec(PAW.GIX), PAW.(vbls{iV})(PAW.GIX),MT.t_uSec);
    end
    MT.(vbls{iV}) = single(MT.(vbls{iV}));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Rotary Encoder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MT.Rot_speed = interp1(ROT.t_uSec(ROT.GIX), ROT.Speed(ROT.GIX),MT.t_uSec,'nearest');
MT.Rot_acc = interp1(ROT.t_uSec(ROT.GIX), ROT.Acc(ROT.GIX),MT.t_uSec,'nearest');
% IMU
MT.IMU_speed = interp1(IMU.t_uS(IMU.GIX), IMU.speed(IMU.GIX),MT.t_uSec);
MT.IMU_absjerk = interp1(IMU.t_uS(IMU.GIX), IMU.absjerk(IMU.GIX),MT.t_uSec);
MT.IMU_speed_pc1 = interp1(IMU.t_uS(IMU.GIX), IMU.speed_pc1(IMU.GIX),MT.t_uSec);
% POS
MT.POS_x = interp1(POS.Time_uS(POS.GIX), POS.COM_xy(POS.GIX,1),MT.t_uSec);
MT.POS_y = interp1(POS.Time_uS(POS.GIX), POS.COM_xy(POS.GIX,2),MT.t_uSec);
MT.POS_speed = interp1(POS.Time_uS(POS.GIX), POS.Speed(POS.GIX),MT.t_uSec);
MT.Is_pulling = false(size(MT.POS_speed));
[~,PULLIX] = Restrict(MT.t_uSec,good_string_pull_intervals_uSec);
PULLIX = PULLIX & MT.Rot_speed > 2; % This gets rid of immobile intervals.
MT.Is_pulling(PULLIX) = true;
revised_string_pull_intervals_uSec = find_intervals([MT.t_uSec(:) double(MT.Is_pulling(:))],.5);

MT.Pull_count = -1*ones(size(MT.POS_speed)); % the pull window.
for iT = 1:length(PULL.Start_uS)
    IX = MT.t_uSec >= PULL.Start_uS(iT) & MT.t_uSec < PULL.End_uS(iT);
    MT.Pull_count(IX) = iT;
end
MT.Pull_count = int16(MT.Pull_count);

% Animate_lines(MT{MT.Is_pulling,2:7})


if PLOT_IT
    
    figure
    plot(MT.Rot_speed)
    
    CORS_lbls = MT.Properties.VariableNames(2:end);
    CORS = corr(Z_scores(MT{MT.Is_pulling,2:end}), 'type', 'Pearson','Rows','pairwise');

    %%%%%%%%%%%%%%%%%%%%%%%
    % let's see all the data...
    ncols = length(CORS_lbls);
    figure
    subplot(1,2,1)
    imagesc(Z_scores(MT{MT.Is_pulling,2:end}))
    set(gca,'XTick',1:ncols)
    set(gca,'XTickLabel',CORS_lbls)
    xtickangle(90)
    
    subplot(1,2,2)
    imagesc(Z_scores(MT{~MT.Is_pulling,2:end}))
    set(gca,'XTick',1:ncols)
    set(gca,'XTickLabel',CORS_lbls)
    xtickangle(90)
    
    figure
    % imagesc(corrcoef(Z_scores(MT{MT.Is_pulling,2:end})))
    imagesc(CORS)
    colorbar
    set(gca,'XTick',1:ncols)
    set(gca,'XTickLabel',CORS_lbls)
    xtickangle(90)
    set(gca,'YTick',1:ncols)
    set(gca,'YTickLabel',CORS_lbls)
    
    figure
    plot3(MT.t_uSec(MT.Is_pulling)/1e6, MT.Nose_x(MT.Is_pulling),MT.Nose_y(MT.Is_pulling),'.')
    
    figure
    plot3(MT.t_uSec(MT.Is_pulling)/1e6, MT.Left_x(MT.Is_pulling),MT.Left_y(MT.Is_pulling),'.')
    hold on
    plot3(MT.t_uSec(MT.Is_pulling)/1e6, MT.Right_x(MT.Is_pulling),MT.Right_y(MT.Is_pulling),'.')
end
