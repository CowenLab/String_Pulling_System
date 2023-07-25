function [SEG, INFO] = SPG_Load_and_Clean_DLC_Front_Camera_Tracking(fname, varargin)
% function [SEG, INFO] = SPG_Load_and_Clean_DLC_Front_Camera_Tracking(fname, varargin)
%
% Load the front camera tracking data from DeepLabCut that was previosly
% converted into a .mat file (typically Front_Cam_Pos.mat)
%
% This function cleans up the data a bit and converts paw movement to
% angles for easier processing and segmenting.
%
% fname is the name of the .mat file
%
% other arguments can be set as tuples after fname (e.g.: 'pth', .4);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pth = .8; % pth is the probabilty threshold for eliminating data. Confidence.
npts_to_smooth_through = 20;
medpts = 4; % to reject some jitter and outliers.
sgolay_order = 7;
sgolay_window = 25;
min_max_th = [50 800];
bandpass_for_each_paw = [1.1 12]; % if < 1 some datasets don't work well
duration_of_a_good_bout_sec = 1; % if less than this, define it as too brief for proper analysis.
interp_meth = 'linear';
Extract_varargin;
POS = []; INFO = [];
GP = SPG_Globals; % parameters for the string pulling data.

if ischar(fname)
    load(fname,'POS')
else
    fname
    disp('WARNING: You are not passing in a filename, assuming you are passing in the POS data')
    POS = fname;
    % return
end

POSold = POS;

sFreq = 1/median(diff(POS.Intan_uS/1e6));
filt_ord_N = 12;
% I tried lower orders, but 22 seemed to rolloff faster so that higher
% frequencies are  not represented.
bpFilt = designfilt('bandpassiir','FilterOrder',filt_ord_N, ...
    'HalfPowerFrequency1',bandpass_for_each_paw(1),'HalfPowerFrequency2',bandpass_for_each_paw(2), ...
    'SampleRate',sFreq,'DesignMethod' ,'butter');

coords = {'Nose' 'Left_Paw' 'Right_Paw'};
for ii = 1:length(coords)
    % fill in the missing points with the median if possible.
    % if not, we could do something moore fancy like ARIMA or kalman filter
    % or a linear model.
    xs = [coords{ii} '_x'];
    ys = [coords{ii} '_y'];
    ys_flipped = [coords{ii} '_y_flipped'];

    ps = [coords{ii} '_likelihood'];

    %     C = Count_contiguous([0; abs(diff(POS.(xs)))]<0.01) > 10; % if no movement for a while, the probably noise.
    %     BIX = POS.(ps) < pth | C(:);
    BIX = POS.(ps) < pth;
    POS.(xs)(BIX) = nan;
    POS.(ys)(BIX) = nan;

    POS.(xs) = movmedian(POS.(xs),medpts,'omitnan');
    POS.(ys) = movmedian(POS.(ys),medpts,'omitnan');
    % smooth this a little more - e.g., for calc of d1
    POS.(xs) = movmean(POS.(xs),medpts,'omitnan');
    POS.(ys) = movmean(POS.(ys),medpts,'omitnan');
    % first derivative (speed does not have a sign).
    POS.([xs '_d1']) = diff([0; POS.(xs)]);
    POS.([ys '_d1']) = diff([0; POS.(ys)]);


    %
    if ~isempty(npts_to_smooth_through)
        v = POS.(xs);
        new_BIX = isnan(v);
        C = Count_contiguous(new_BIX);
        IIX = C<npts_to_smooth_through & C > 0;
        v(IIX) = interp1(POS.Intan_uS(~BIX), v(~BIX), POS.Intan_uS(IIX),interp_meth);
        vv = sgolayfilt(v,sgolay_order,sgolay_window);
        %         figure;plot(POS.(xs));hold on;plot(v);plot(vv)
        POS.(xs) = vv;

        v = POS.(ys);
        new_BIX = isnan(v);
        C = Count_contiguous(new_BIX);
        IIX = C<npts_to_smooth_through & C > 0;
        v(IIX) = interp1(POS.Intan_uS(~BIX), v(~BIX), POS.Intan_uS(IIX),interp_meth);
        vv = sgolayfilt(v,sgolay_order,sgolay_window);
        %         figure;plot(POS.(xs));hold on;plot(v);plot(vv)
        vv(vv<min_max_th(1) | vv>min_max_th(2)) = nan;
        POS.(ys) = vv;

    end
    POS.(ys_flipped) = GP.vertical_pixels - POS.(ys);
    [v, a] = Speed_from_xy([POS.Intan_uS/1e6  POS.(xs)  POS.(ys)]);
    v(v>10000) = nan; % clearly an extreme
    a(a>10000) = nan; % clearly an extreme
    POS.([coords{ii} '_speed']) = v;
    POS.([coords{ii} '_acc']) = a;
    % With this information, identify contiguous blocks of data where the
    % tracking was particulalry good. This will be important when analyzing
    % data so that we only evaluate periods when tracking was excellent.

    % Find the good bouts in the data
    GIX = ~isnan(POS.(ys));
    % this ensure that we can mark the start and end time.
    GIX(1) = false; GIX(end) = false;

    inter_ix = find_intervals(GIX,.2);
    st_s = POS.Intan_uS(inter_ix(:,1))/1e6;
    ed_s = POS.Intan_uS(inter_ix(:,2))/1e6;
    good_intervals = inter_ix(ed_s-st_s >= duration_of_a_good_bout_sec,:);
    %
    goodpername = ['good_pull_periods_' coords{ii}];
    POS.(goodpername) = false(size(POS.Intan_uS));
    for iR = 1:Rows(good_intervals)
        POS.(goodpername)(good_intervals(iR,1):good_intervals(iR,2)) = true;
    end

    if ~strcmpi(coords{ii},'nose')
        yr = POS.(ys_flipped);
        yr = yr - movmean(yr,ceil(sFreq*4),'omitnan');
        IX = POS.(goodpername) & ~isnan(yr);

        yrf = nan(size(yr));
        ph = nan(size(yr));

        if sum(IX) > 2
            yrf(IX) = filtfilt(bpFilt,yr(IX));
            ph(IX) = angle(hilbert(yrf(IX)))+pi; % add the pi so that it goes from 0 to 2pi or 0 360.
            if 0
                figure
                subplot(1,2,1)
                plot(ph,yr,'.')
                subplot(1,2,2)
                plot(ph,POS.([coords{ii} '_speed']),'.')
                figure
                plot(yr)
                hold on
                plot(yrf)
                yyaxis right
                plot(ph)
            end
        end
        POS.([coords{ii} '_phase']) = ph;
    end
end
% When the tracking worked...
all_good_pull_periods = POS.good_pull_periods_Left_Paw & POS.good_pull_periods_Right_Paw;
% when his nose is low - indicates not a good pull position.
all_good_pull_periods(POS.Nose_y > 550 ) = false;
% paws should be moving a little to be a good period...
GIX = (POS.Left_Paw_speed + POS.Right_Paw_speed)/2 > 0.01 & (POS.Left_Paw_speed + POS.Right_Paw_speed)/2 < 15000;
all_good_pull_periods(~GIX) = false;
% From teh above, determing the good intevals.
INFO.good_pull_intervals_ix = find_intervals(all_good_pull_periods,.5);
% get rid of very short intervals.
dur_s = (INFO.good_pull_intervals_ix(:,2) - INFO.good_pull_intervals_ix(:,1))/sFreq;
INFO.good_pull_intervals_ix = INFO.good_pull_intervals_ix(dur_s >= duration_of_a_good_bout_sec,:);

all_good_ix = [];
for iR = 1:Rows(INFO.good_pull_intervals_ix)
    all_good_ix = [all_good_ix INFO.good_pull_intervals_ix(iR,1):INFO.good_pull_intervals_ix(iR,2)];
end
POS.good_pull_periods_all = false(Rows(POS),1);
POS.good_pull_periods_all(all_good_ix) = true;

INFO.good_pull_intervals_uSec = POS.Intan_uS(INFO.good_pull_intervals_ix);
% angle between the paws relative to the right paw
v = [POS.Right_Paw_x POS.Right_Paw_y] - [POS.Left_Paw_x POS.Left_Paw_y];
POS.Ang_Between_Paws_Rad = atan2(v(:,2),v(:,1));
POS.Dist_Between_Paws_Pix = sqrt(v(:,1).^2 + v(:,2).^2);

POS.Right_x_to_nose = POS.Right_Paw_x - POS.Nose_x;
POS.Right_y_to_nose = POS.Right_Paw_y - POS.Nose_y;

POS.Left_x_to_nose = POS.Left_Paw_x - POS.Nose_x;
POS.Left_y_to_nose = POS.Left_Paw_y - POS.Nose_y;
% Distance relative to the nose may be an excellent marker of the reach.
POS.Left_dist_to_nose = sqrt(POS.Left_x_to_nose.^2 + POS.Left_y_to_nose.^2 );
POS.Right_dist_to_nose = sqrt(POS.Right_x_to_nose.^2 + POS.Right_y_to_nose.^2 );

lrx  = POS.Left_Paw_x - POS.Right_Paw_x;
lry  = POS.Left_Paw_y - POS.Right_Paw_y;

POS.Dist_Left_to_Right_Pix = sqrt(lrx.^2 + lry.^2 );

% PCA - might at some point be useful for summarizing movement in a single
% dimension or segmenting phases of movement. Problem - if performed on raw
% data will be subject to non-stationarities so to generalize, let's do _d1.
% Why does adding speed screw up the segmentation????
% M = [POS.Right_Paw_x_d1 POS.Right_Paw_y_d1 POS.Left_Paw_x_d1 POS.Left_Paw_y_d1 sin(POS.Left_Paw_phase) cos(POS.Left_Paw_phase) sin(POS.Right_Paw_phase) cos(POS.Right_Paw_phase) sin(POS.Ang_Between_Paws_Rad) cos(POS.Ang_Between_Paws_Rad) ];
% M = [[0;diff(sin(POS.Left_Paw_phase))]  [0;diff(sin(POS.Right_Paw_phase))] sin(POS.Left_Paw_phase) cos(POS.Left_Paw_phase) sin(POS.Right_Paw_phase) cos(POS.Right_Paw_phase) sin(POS.Ang_Between_Paws_Rad) cos(POS.Ang_Between_Paws_Rad) ];
M = [ POS.Left_Paw_x_d1 POS.Left_Paw_y_d1  POS.Right_Paw_x_d1 POS.Right_Paw_y_d1  sin(POS.Left_Paw_phase) cos(POS.Left_Paw_phase) sin(POS.Right_Paw_phase) cos(POS.Right_Paw_phase) sin(POS.Ang_Between_Paws_Rad) cos(POS.Ang_Between_Paws_Rad) ];
ML = [  POS.Left_Paw_x_d1 POS.Left_Paw_y_d1 [0;diff(sin(POS.Left_Paw_phase))]  [0;diff(cos(POS.Left_Paw_phase))]  sin(POS.Left_Paw_phase) cos(POS.Left_Paw_phase)  ]; %sin(POS.Ang_Between_Paws_Rad)  cos(POS.Ang_Between_Paws_Rad)
MR = [ POS.Right_Paw_x_d1 POS.Right_Paw_y_d1 [0;diff(sin(POS.Right_Paw_phase))]  [0;diff(cos(POS.Right_Paw_phase))] sin(POS.Right_Paw_phase) cos(POS.Right_Paw_phase)  ]; % sin(POS.Ang_Between_Paws_Rad)  cos(POS.Ang_Between_Paws_Rad)
% M = [POS.Right_Paw_x_d1 POS.Right_Paw_y_d1 POS.Left_Paw_x_d1 POS.Left_Paw_y_d1];

% M2 = [POS.Right_Paw_x POS.Right_Paw_y POS.Left_Paw_x POS.Left_Paw_y];
%  M = [M M2];
M(~POS.good_pull_periods_Right_Paw,:) = nan;
ML(~POS.good_pull_periods_Left_Paw,:) = nan;
MR(~POS.good_pull_periods_Right_Paw,:) = nan;
[~,sc] = pca(Z_scores(M));
[~,scL] = pca(Z_scores(ML));
[~,scR] = pca(Z_scores(MR));
sc = single(sc); scL = single(scL); scR = single(scR);
% Find a lower dimensional representation of the paw movements.
% This might be an additional way to remove bad frames and plot
% trajectories

POS.PC1 = sc(:,1);
POS.PC2 = sc(:,2);
POS.PC3 = sc(:,3);

POS.PC1_Left = scL(:,1);
POS.PC2_Left = scL(:,2);
POS.PC3_Left = scL(:,3);

POS.PC1_Right = scR(:,1);
POS.PC2_Right = scR(:,2);
POS.PC3_Right = scR(:,3);

% With all of this information, segment out the reach phases and reach cycles..
[SEG, INFO.PAWSEG] = SPG_segment_reach_and_withdrawal(POS); % ,INFO.good_pull_intervals_uSec

if 0
    warning off
    % 2 versions... kmeans or tree...
    % Currently - I do not see the direct usefullness but it might be useful
    % for future segmentation efforts.
    c = int16(kmeans(Z_scores(M),10));
    cL = int16(kmeans(Z_scores(ML),8));
    cR = int16(kmeans(Z_scores(MR),8));
    c = clusterdata(Z_scores(M),'Linkage','ward','SaveMemory','on','Maxclust',10);
    cL = clusterdata(Z_scores(ML),'Linkage','ward','SaveMemory','on','Maxclust',8);
    cR = clusterdata(Z_scores(MR),'Linkage','ward','SaveMemory','on','Maxclust',8);
    warning on

    figure;
    subplot(1,3,1);scatter3(sc(:,1),sc(:,2),sc(:,3),10,c,'filled')
    subplot(1,3,2);scatter3(scL(:,1),scL(:,2),scL(:,3),10,c,'filled'); title('Left')
    subplot(1,3,3);scatter3(scR(:,1),scR(:,2),scR(:,3),10,c,'filled'); title('Right')
    % comet3(sc(:,1),sc(:,2),sc(:,3))

    GIX = POS.good_pull_periods_Right_Paw & POS.good_pull_periods_Left_Paw;
    figure;
    subplot(3,1,1);gscatter(POS.Left_Paw_phase(GIX), scL(GIX,1) + scR(GIX,1)  , c(GIX))
    subplot(3,1,2);gscatter(POS.Left_Paw_phase(GIX), POS.Left_Paw_speed(GIX), cL(GIX))
    subplot(3,1,3);gscatter(POS.Right_Paw_phase(GIX), POS.Right_Paw_speed(GIX), cR(GIX))
end

% VALIDATION AND ALIGNMENT ACROSS SESSIONS
%
% attempt to align the phases so that they are consistent between sessions
% and rats. For some reason, everything aligns
load(fullfile(Git_dir,'String_Pull_312A','Pull_phase_alignment.mat'),'ALIGN')

GIX = POS.good_pull_periods_all;
for ii = 1:(length(ALIGN.phase_intervals_rad )-1)
    IX = GIX & POS.Left_Paw_phase > ALIGN.phase_intervals_rad (ii) &  POS.Left_Paw_phase <= ALIGN.phase_intervals_rad (ii+1) ;
    left_paw_speed(ii) = median(POS.Left_Paw_speed(IX),'omitnan');
    IX = GIX & POS.Right_Paw_phase > ALIGN.phase_intervals_rad (ii) &  POS.Right_Paw_phase <= ALIGN.phase_intervals_rad (ii+1) ;
    right_paw_speed(ii) = median(POS.Right_Paw_speed(IX),'omitnan');
end
% do the cross corr...
% [xc,lags] = xcorr(left_paw_speed,ALIGN.left_paw_speed);
BIX = isnan(right_paw_speed) | isnan(ALIGN.right_paw_speed);
if any(BIX)
    disp('found nans in paw speed')
end
[xc,lags] = xcorr(right_paw_speed(~BIX),ALIGN.right_paw_speed(~BIX));
[~,ix] = max(xc);
%     NOTE: I did this and ony one small shift off between sessions and
%     rats in some sets in 348 and 349. Not worth adjusting. - only one lag
%     off.
INFO.xcorr_align_reach_phase_shift = lags(ix);
INFO.xcorr = xc;
INFO.xcorr_lags = lags;
INFO.xcorr_phase_intervals_rad = ALIGN.phase_intervals_rad;

% From these data, we can further process to get other parameters such as
% detailed paw phase, acceleration, etc.
% this effectively adds some new columns to the master table.
% SPG_process_paw_data; - does the right start up pull times.
% SPG_Segment_Pulls_Further;