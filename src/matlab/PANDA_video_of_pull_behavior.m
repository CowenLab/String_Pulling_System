function OUT = SPG_video_of_pull_behavior(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run this function in the data directory.
% 
% This plots video with behavior measures, NOT neural data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
OUT_DIR = 'D:\Temp\behavior_vids\'; % SSD. This is where the raw video will be temp stored and where the output videos will go.
TEMP_RAW_VID_DIR = 'D:\Temp\behavior_vids\Raw_vids\';
mk2 = 24;
y_offset = 300;
fig_pos = [126 97 1247 763];
COPY_VID_TO_LOCAL_FOLDER = false; % make a local copy of the video. This might be useful if data is stored on a network drive. Typically it is not worth it.

Extract_varargin;

close all; fclose all; % ensure nothing else is open.
OUT = [];
SES = SPG_Session_Info();
GP = SPG_Globals;
OUT.SES = SES;
OUT.aborted = false;

% Determine where to save videos
dest_dir = fullfile(OUT_DIR,'String_Pull_312',SES.title_str);
if COPY_VID_TO_LOCAL_FOLDER
    % copy the raw vid to a local directory.
    in_vid_fname = fullfile(TEMP_RAW_VID_DIR,[SES.title_str '.mp4']);
else
    in_vid_fname = SES.Raw_videos_front_fname; % use the original video.
end
mkdir_cowen({OUT_DIR TEMP_RAW_VID_DIR dest_dir})

%% Load Data %%
% determine if this session has a front camera video or mat file. If not,
% abort.
if ~exist(fullfile(SES.Front_cam_dir,'Front_Cam_Pos.mat'),'file') || isempty(SES.Raw_videos_front_fname)
    OUT.aborted = true;
    pwd
    disp('Could not find a Front Cam Pos Mat file. Aborted this session.')
    return
end

FCam = SPG_Load_and_Clean_DLC_Front_Camera_Tracking(fullfile(SES.Front_cam_dir,'Front_Cam_Pos.mat'));
IMU = SPG_Load_and_Process_IMU(fullfile(SES.Intan_rec_dir,'Inertial_data.mat'));
load(fullfile(SES.Intan_rec_dir,'EVT.mat'),'EVT');
% E = SPG_Load_Events_From_Excel(SES.Event_times_file);
% Extract rotary encoder speed from the EVT timestamps...
ROT = SPG_Rotary_Encode_Speed();
% For each bout, find the appropriate indices in the data...
IX_fcam = []; IX_IMU = []; IX_ROT = [];
for iB = 1:Rows(ROT.good_string_pull_intervals_uSec)
    sted = ROT.good_string_pull_intervals_uSec(iB,1:2);
    IX_fcam{iB} = FCam.Intan_uS >= sted(1) & FCam.Intan_uS <= sted(2);
    IX_IMU{iB} = IMU.t_uS >= sted(1) & IMU.t_uS <= sted(2);
    IX_ROT{iB} = ROT.t_uSec >= sted(1) & ROT.t_uSec <= sted(2);
end
%
% Overlay with the video
% First make a local copy (assumes the original data is stored on a slow drive (USB or network).
if COPY_VID_TO_LOCAL_FOLDER || ~exist(in_vid_fname,'file')% Just do this once and then they should all be in the SSD.
    % assume that these files have already been copied.
    fprintf('Copying %s to %s - takes a while.\n',  SES.Raw_videos_front_fname, in_vid_fname)
    copyfile_xcopy(SES.Raw_videos_front_fname,in_vid_fname);
    %     copyfile(SES.Raw_videos_front_fname,in_vid_fname);
    disp('Complete')
end
% Create the video object
vidObj = VideoReader(in_vid_fname); % reading gets exponentially slower as frames are read. A problem. ALso - need to set the proper frame rate.
% last = read(vidObj,inf); % this should force it to determine the number of frames which may help speed things up. Does not seem to help either.
matlab.video.read.UseHardwareAcceleration('on') %Don't know if this will help or hurt. Did not help
last_toc = 0;
toc_cnt = 1;
vid_proc_time = [];
tic; % for tracking video processing speed.
% opengl software % try this - desperate to find things that speed up
% video. Seemed to slow it down
% Next step - use XData and YData to update plot.
% remove the subplots to see if that speeds things up.
for iB = 1:Rows(ROT.good_string_pull_intervals_uSec)
    % You will need to estimate string speed and IMU for each frame as well
    % probably using interp unless it's in the FCam data.
    n_good_frames = sum(FCam.Left_Paw_y(IX_fcam{iB})> 0.01,'omitnan');
    if n_good_frames < 300 % skip if bout is less than 300 frames (1 sec)
        % I do not understand how this could happen unless perhaps the
        % camera started before recording? too much noise in the video so
        % no good paw xy data?
        disp(['Block ' num2str(iB) ' too short, noisy, or bad frames. n_frames:' num2str(n_good_frames)])
        continue
    end
    frames_ix = find(IX_fcam{iB});
    dur_s = (FCam.Intan_uS(frames_ix(end)) - FCam.Intan_uS(frames_ix(1)))/1e6;
    % data: IMU and String Speed.
    IMU_for_vid = interp1(IMU.t_uS(IX_IMU{iB}), IMU.speed_pc1(IX_IMU{iB}),FCam.Intan_uS(frames_ix));
    string_speed_for_vid = interp1(ROT.t_uSec(IX_ROT{iB}), ROT.Speed(IX_ROT{iB}),FCam.Intan_uS(frames_ix));
    out_file = fullfile(dest_dir,sprintf('%s_Blk%d.mp4',SES.title_str,iB));
    vidWriteObj = VideoWriter(out_file,'MPEG-4');
    open(vidWriteObj)
    close all % I think this helps

    FigObj = figure(202);
    set(FigObj,'Position',fig_pos)
    clf
    % I think one thing that can kill processing is if you have another
    % video open or playing outside of matlab. Be sure all video players
    % are closed. I had a video going and the time/block went up linearly.
    for iF = 1:length(frames_ix)
        clf   % So dumb. - OK it helped a lot, but did not fixt. there is a slow
        % gradual increase in processing time across files now. That also
        % got fixed - I think with the cla after the first subplot
        vid = read(vidObj,frames_ix(iF)); % even avoiding the read - still slows down.
        %         vid = readFrame(vidObj,'native'); % tried this instead of read - still slow.
        subplot(3,2,1:2:6)
        cla
        imshow(vid,[]);

        hold on
        plot(FCam.Left_Paw_x(frames_ix(iF)),FCam.Left_Paw_y(frames_ix(iF)),'y.','MarkerSize',8)
        plot(FCam.Left_Paw_x(frames_ix(iF)),FCam.Left_Paw_y(frames_ix(iF)),'o','color',GP.Colors.LeftPaw,'MarkerSize',8)
        plot(FCam.Right_Paw_x(frames_ix(iF)),FCam.Right_Paw_y(frames_ix(iF)),'y.','MarkerSize',8)
        plot(FCam.Right_Paw_x(frames_ix(iF)),FCam.Right_Paw_y(frames_ix(iF)),'o','color',GP.Colors.RightPaw,'MarkerSize',8)

        plot(FCam.Nose_x(frames_ix(iF)),FCam.Nose_y(frames_ix(iF)),'c.','MarkerSize',8)
        plot(FCam.Nose_x(frames_ix(iF)),FCam.Nose_y(frames_ix(iF)),'o','color',GP.Colors.Nose,'MarkerSize',8)

        hold off
        title(sprintf('%s Bk %d/%d, %1.2f s, Fr %d/%d',strrep(SES.title_str,'_',' '),iB,Rows(ROT.good_string_pull_intervals_uSec),dur_s,frames_ix(iF),frames_ix(end)))

        subplot(3,2,2)
        cla
        plot(FCam.Intan_uS(frames_ix(1:5:end)), string_speed_for_vid(1:5:end),'k.-')
        title('string speed');axis tight; hold on
        plot(FCam.Intan_uS(frames_ix(iF)), string_speed_for_vid(iF),'r.','Markersize',mk2)
        axis off

        subplot(3,2,4)
        cla
        ix = frames_ix(1:10:end);
        plot(FCam.Intan_uS(ix), FCam.Left_Paw_x(ix),'k.-')
        hold on
        plot(FCam.Intan_uS(ix), FCam.Right_Paw_x(ix),'b.-')
        plot(FCam.Intan_uS(ix), FCam.Left_Paw_y_flipped(ix)+y_offset,'k.-')
        plot(FCam.Intan_uS(ix), FCam.Right_Paw_y_flipped(ix)+y_offset,'b.-')

        plot(FCam.Intan_uS(ix), FCam.Nose_x(ix),'.-','Color',[.7 .1 .2])
        plot(FCam.Intan_uS(ix), FCam.Nose_y_flipped(ix)+y_offset,'.-','Color',[.6 .2 .2])
        plot(FCam.Intan_uS(frames_ix(iF)), FCam.Nose_x(frames_ix(iF)),'.','color',GP.Colors.Nose,'MarkerSize',mk2)
        plot(FCam.Intan_uS(frames_ix(iF)), FCam.Nose_y_flipped(frames_ix(iF))+y_offset,'.','color',GP.Colors.Nose,'MarkerSize',mk2)

        plot(FCam.Intan_uS(frames_ix(iF)), FCam.Left_Paw_x(frames_ix(iF)),'.','color',GP.Colors.LeftPaw,'MarkerSize',mk2)
        plot(FCam.Intan_uS(frames_ix(iF)), FCam.Left_Paw_y_flipped(frames_ix(iF))+y_offset,'.','color',GP.Colors.LeftPaw,'MarkerSize',mk2)
        plot(FCam.Intan_uS(frames_ix(iF)), FCam.Right_Paw_x(frames_ix(iF)),'.','color',GP.Colors.RightPaw,'MarkerSize',mk2)
        plot(FCam.Intan_uS(frames_ix(iF)), FCam.Right_Paw_y_flipped(frames_ix(iF))+y_offset,'.','color',GP.Colors.RightPaw,'MarkerSize',mk2)
        title('each paw x y and nose'); axis tight; axis off

        subplot(3,2,6)
        cla
        plot(FCam.Intan_uS(frames_ix(1:5:end)), IMU_for_vid(1:5:end),'k.-')
        hold on
        plot(FCam.Intan_uS(frames_ix(iF)), IMU_for_vid(iF),'r.','Markersize',mk2)
        title('IMU'); axis tight; axis off

        % Save the frame
        fr = getframe(FigObj);
        writeVideo(vidWriteObj,fr)% I commented out the writing and it was still slow - so not the writing.
        if mod(frames_ix(iF),100)==0
            vid_proc_time(toc_cnt) = toc - last_toc;
            last_toc = toc;
            fprintf('%d/%d %1.3f,',frames_ix(iF), length(frames_ix), vid_proc_time(toc_cnt))
            toc_cnt = toc_cnt + 1;
        end
    end

    close(vidWriteObj)

end

figure(10101)
clf
plot(vid_proc_time)
title(strrep(SES.title_str,'_',' '));xlabel('bout');ylabel('sec')
saveas(gcf,fullfile(dest_dir,sprintf('vid_proc_time_%s.png',SES.title_str)))


