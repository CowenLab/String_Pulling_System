function INTAN_Post_Process_Rm_312A_top_camera(DATA_DIR)
% Assumes that deeplab cut has been run and that the INTAN data has been
% post-processed. The deep lab cut directory (DLC) should be in the directory 
% ABOVE the INTAN data directory.
%  e.g.: 'Z:\Data\String_Pull_312a\RECORDING SESSIONS\Rat 333\3\DLC'
%
% INPUT:
%   DATA_DIR - the root directory where the INTAN data was stored
%     for example: 'Z:\Data\String_Pull_312a\RECORDING SESSIONS\Rat 333\3\Rec_210818_101300'
%   extra args...
%   set different PRM. variables to change what occurs in this code.
%
%
% Cowen 2021


PRM.PIX_PER_CM_TOPDOWN = nan; % This is not known yet. Needs to be determined.
% Get the video directory and file.
VID_DIR = fileparts(DATA_DIR);
VID_DIR = fullfile(VID_DIR,'DLC','Top_Cam');
d = dir(fullfile(VID_DIR,'*.csv'));
if length(d) < 1
    VID_DIR
    error('No .csv file from DeepLabCut found')
end
if length(d) > 1
    VID_DIR
    error('Multiple .csv files found')
end
VID_FILE = d(1).name;
VID_FILE_PATH = fullfile(VID_DIR,VID_FILE);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process tracking data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist(fullfile(POS_FILE),'file')
    disp('POSITION FILE DOES NOT EXIST!!! Skipping.')
    PRM.extract_position = false; %
end
% Following is old legacy data. New data is processed via DeepLabCut.
if PRM.extract_position
    
    pos_out_file = fullfile(DATA_DIR,'POS.mat');

    [~,fname,ext] = fileparts(POS_FILE);
    
    if ~exist(fullfile(DATA_DIR,fname),'file')
        copyfile(POS_FILE, DATA_DIR)
        disp('Copied pos file to local data dir folder.')
        POS_FILE = fullfile(DATA_DIR,[fname ext]);
    end
    
    P = dlmread(POS_FILE,'\t',1);
    POS = [];
    if abs(Rows(P)-length(EVT.pos_frame_ID)) > 5
        disp('problems. video recording might have been started before recording or continued after recording was turned off')
        disp('Assuming first record is OK.')
    end
    df = Rows(P) - length(EVT.pos_frame_ID);
    if df >= 0
        P(1:length(EVT.pos_frame_ID),8) = EVT.pos_frame_ID;
    else
        P(:,8) = EVT.pos_frame_ID(1:Rows(P));
    end
    P(:,9) = 1e6*P(:,8)/fs_initial;
    GIX = P(:,9) > 0;
    P = P(GIX,:);
    POS.Time_uS = P(:,9);
    POS.RecID = P(:,8);
    POS.Red_xy = P(:,1:2); 
    POS.Green_xy = P(:,3:4); 
    POS.Blue_xy = P(:,5:6);
    POS.Speed_Red = [];
    if sum(sum(sum(POS.Red_xy)))> 10
        POS.Speed_Red = Speed_from_xy([ POS.Time_uS POS.Red_xy],[],1);
    end
    POS.Speed_Green = [];
    if sum(sum(sum(POS.Green_xy)))> 10
        POS.Speed_Green = Speed_from_xy([ POS.Time_uS POS.Green_xy],[],1);
    end
    
    POS.Red_xy = single(POS.Red_xy);
    POS.Green_xy = single(POS.Green_xy);
    POS.Blue_xy = single(POS.Blue_xy);
    POS.Speed_Red = single(POS.Speed_Red);
    POS.Speed_Green = single(POS.Speed_Green);
    
    save(pos_out_file,'POS')
    
    figure(1)
    subplot(2,2,1:2)
    plot(POS.Time_uS/3600e6,POS.Green_xy(:,1),'Color',[.1 .9 .1]);
    hold on
    plot(POS.Time_uS/3600e6,POS.Green_xy(:,2),'Color',[.2 .8 .1]);
    plot(POS.Time_uS/3600e6,POS.Red_xy(:,1),'Color',[.9 .1 .1]);
    plot(POS.Time_uS/3600e6,POS.Red_xy(:,2),'Color',[.8 .2 .2]);
    xlabel('Hours')
    axis tight
    subplot(2,2,3)
    plot(POS.Red_xy(:,1),POS.Red_xy(:,2),'r.','MarkerSize',1)
    hold on
    plot(POS.Green_xy(:,1),POS.Green_xy(:,2),'g.','MarkerSize',1)
    axis tight
    subplot(2,2,4)
    if ~isempty(POS.Speed_Red)
        plot(POS.Time_uS/3600e6,POS.Speed_Red,'r')
    end
    hold on
    if ~isempty(POS.Speed_Green)
        plot(POS.Time_uS/3600e6,POS.Speed_Green,'g')
    end
    axis tight
end