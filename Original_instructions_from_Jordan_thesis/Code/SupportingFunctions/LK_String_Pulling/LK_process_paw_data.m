function [PAW2,EVENTS] = LK_process_paw_data(PAW, good_string_pull_intervals_uSec)
% function [PAW2,GIX,GIXl,GIXr,INFO] = LK_process_paw_data(PAW, good_string_pull_intervals_uSec)
%
% Clean up and process the paw data.

% INPUT: PAW table from DeepLabCut
%        good string start end times.
%
% Adds new information such as each paw's location relative to the rat's
% nose.
%
% returns indices of GOOD data and indices to good data for all points and
% for the left and right paw in GIX, GIXl, GIXr.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Cowen 2020.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
INFO = [];
if ischar(PAW)
    if exist(PAW,'file')
        tmp = load(PAW);
        PAW = tmp.T2;
    else
        disp(PAW)
        error('Could not find file')
    end
end
n_contig_thr = 25; % this is like 100 msec. It's my choice, but could be looked at systematically. It determines the threshold for a pull up or down.

PAW2 = PAW;
bad_speed_thresh = .5e4;
[PAW2.Right_speed, PAW2.Right_acc] = LK_Speed_from_xy(PAW.Time_uSec/1e6, PAW.Right_x, PAW.Right_y, bad_speed_thresh);
[PAW2.Left_speed, PAW2.Left_acc] = LK_Speed_from_xy(PAW.Time_uSec/1e6, PAW.Left_x, PAW.Left_y, bad_speed_thresh);
[PAW2.Nose_speed] = LK_Speed_from_xy(PAW.Time_uSec/1e6,PAW.Nose_x, PAW.Nose_y, bad_speed_thresh);

PAW2.Right_x_to_nose = PAW.Right_x - PAW.Nose_x;
PAW2.Right_y_to_nose = PAW.Right_y - PAW.Nose_y;

PAW2.Left_x_to_nose = PAW.Left_x - PAW.Nose_x;
PAW2.Left_y_to_nose = PAW.Left_y - PAW.Nose_y;
% Distance relative to the nose may be an excellent marker of the reach.
PAW2.Left_dist_to_nose = sqrt(PAW2.Left_x_to_nose.^2 + PAW2.Left_y_to_nose.^2 );
PAW2.Right_dist_to_nose = sqrt(PAW2.Right_x_to_nose.^2 + PAW2.Right_y_to_nose.^2 );

lrx  = PAW.Left_x - PAW.Right_x;
lry  = PAW.Left_y - PAW.Right_y;


PAW2.Dist_Left_to_Right = sqrt(lrx.^2 + lry.^2 );


PAW2.Right_speed = movmedian(PAW2.Right_speed,5,'omitnan');
PAW2.Left_speed = movmedian(PAW2.Left_speed,5,'omitnan');
PAW2.Right_acc = movmedian(PAW2.Right_acc,5,'omitnan');
PAW2.Left_acc = movmedian(PAW2.Left_acc,5,'omitnan');

%% % Find the indices of good data.
GIX = false(size(PAW.Time_uSec));
for ii = 1:Rows(good_string_pull_intervals_uSec)
    GIX = GIX | PAW2.Time_uSec > good_string_pull_intervals_uSec(ii,1) & PAW2.Time_uSec < good_string_pull_intervals_uSec(ii,2);
end
GIX(PAW2.Right_x > 375) = false;
GIX(PAW2.Left_x > 375) = false;
GIX(PAW2.Right_x < 60) = false;
GIX(PAW2.Left_x < 60) = false;
GIX(PAW2.Right_y > 700) = false;
GIX(PAW2.Left_y > 700) = false;

GIXr = PAW2.Right_x > 0 & PAW2.Right_y > 0 & PAW2.Right_speed > 3.6309e-05 & GIX;
GIXl = PAW2.Left_x > 0 & PAW2.Left_y > 0 & PAW2.Left_speed > 3.6309e-05  & GIX;
PAW2.GIX = GIX;
PAW2.GIXr = GIXr;
PAW2.GIXl = GIXl;

% Compute the first derivatitive..
PAW2.Right_y_d1 = diff([0;PAW2.Right_y]);
PAW2.Left_y_d1 = diff([0;PAW2.Left_y]);


if nargout > 1
    % Determine meaningful events from the paw data.
    % Find a contiguous rise and a contiguous fall.
    th_pix = 5; % minimum of vertical distance that must be traversed.
    
    [~,block_sizes,st,ed]  = Count_contiguous(PAW2.Right_y_d1>0);
    % dist from start to end of pull must be postive and above a certain th.
    GIX = PAW2.Right_y(ed) - PAW2.Right_y(st) >= th_pix & block_sizes(:) > n_contig_thr(:);
    EVENTS.Right_start_up_t_uS = PAW2.Time_uSec(st(GIX));
    EVENTS.Right_end_up_t_uS = PAW2.Time_uSec(ed(GIX));
    %%%%%%%
    [~,block_sizes,st,ed]  = Count_contiguous(PAW2.Right_y_d1<0);
    GIX = PAW2.Right_y(ed) - PAW2.Right_y(st) <= -1*th_pix & block_sizes(:) > n_contig_thr(:);
    EVENTS.Right_start_down_t_uS = PAW2.Time_uSec(st(GIX));
    EVENTS.Right_end_down_t_uS = PAW2.Time_uSec(ed(GIX));
    %%%%%%%
    [~,block_sizes,st,ed]  = Count_contiguous(PAW2.Left_y_d1>0);
    GIX = PAW2.Left_y(ed) - PAW2.Left_y(st) >= th_pix & block_sizes(:) > n_contig_thr(:);

    EVENTS.Left_start_up_t_uS = PAW2.Time_uSec(st(GIX));
    EVENTS.Left_end_up_t_uS = PAW2.Time_uSec(ed(GIX));
    
    [~,block_sizes,st,ed]  = Count_contiguous(PAW2.Left_y_d1<0);
    GIX = PAW2.Left_y(ed) - PAW2.Left_y(st) <= -1*th_pix & block_sizes(:) > n_contig_thr(:);

    EVENTS.Left_start_down_t_uS = PAW2.Time_uSec(st(GIX));
    EVENTS.Left_end_down_t_uS = PAW2.Time_uSec(ed(GIX));
    
    

    
    
    [~,ix] = findpeaks(PAW2.Right_y);
    EVENTS.Right_peak_y_t_uS = PAW2.Time_uSec(ix);
    [~,ix] = findpeaks(-1*PAW2.Right_y);
    EVENTS.Right_trough_y_t_uS = PAW2.Time_uSec(ix);
    [~,ix] = findpeaks(PAW2.Left_y);
    EVENTS.Left_peak_y_t_uS = PAW2.Time_uSec(ix);
    [~,ix] = findpeaks(-1*PAW2.Left_y);
    EVENTS.Left_trough_y_t_uS = PAW2.Time_uSec(ix);
    %{
    figure
    plot(PAW2.Time_uSec,PAW2.Left_y,PAW2.Time_uSec,PAW2.Right_y)
    hold on
     plot(EVENTS.Right_start_up_t_uS ,nanmean(PAW2.Right_y)*ones(size(EVENTS.Right_start_up_t_uS )),'g^')
     plot(EVENTS.Right_start_down_t_uS ,nanmean(PAW2.Right_y)*ones(size(EVENTS.Right_start_down_t_uS )),'g+')
     plot(EVENTS.Left_start_up_t_uS ,nanmean(PAW2.Left_y)*ones(size(EVENTS.Left_start_up_t_uS )),'b^')
     plot(EVENTS.Left_start_down_t_uS ,nanmean(PAW2.Left_y)*ones(size(EVENTS.Left_start_down_t_uS )),'b+')
    %}
end

% Abandoning the PCA of the paw for now as for many datasets, there is not
% solid data so that we don't have simultaneous data for both paws at the
% same time.
% M = [PAW2.Right_x PAW2.Left_x PAW2.Right_y PAW2.Left_y PAW2.Right_speed PAW2.Left_speed ];
% [pc,~,INFO.lat1] = pca(M(GIX,:));
% PAW2.PC1 = M*pc(:,1); % Convert to scores.
% PAW2.PC2 = M*pc(:,2); % Convert to scores.
% M = [PAW2.Right_x_to_nose PAW2.Right_y_to_nose PAW2.Left_x_to_nose PAW2.Left_y_to_nose PAW2.Right_dist_to_nose PAW2.Left_dist_to_nose ];
% [pc,~,INFO.lat2] = pca(M(GIX,:));
% PAW2.PC1tonose = M*pc(:,1); % Convert to scores.
% PAW2.PC2tonose = M*pc(:,2); % Convert to scores.
%%
if nargout == 0
    GP = LK_Globals;
    
    figure
    subplot(1,2,1)
    plot(PAW2.Left_x,PAW2.Left_y,'.','Color',GP.Colors.LeftPaw,'MarkerSize',1)
    hold on
    plot(PAW2.Right_x,PAW2.Right_y,'.','Color',GP.Colors.RightPaw,'MarkerSize',1)
    xlabel('x');ylabel('y');
    legend('Left','Right');legend boxoff
    subplot(1,2,2)
    plot(PAW2.Left_x_to_nose,PAW2.Left_y_to_nose,'.','Color',GP.Colors.LeftPaw,'MarkerSize',1)
    hold on
    plot(PAW2.Right_x_to_nose,PAW2.Right_y_to_nose,'.','Color',GP.Colors.RightPaw,'MarkerSize',1)
    
    figure
    plot(PAW2.Nose_x,PAW2.Nose_y,'.','Color',GP.Colors.Nose,'MarkerSize',1)
    xlabel('x');ylabel('y');
    
    if 0
        figure
        plot(PAW2.PC1,PAW2.PC2,'.','MarkerSize',1)
        hold on
        plot(PAW2.PC1tonose,PAW2.PC2tonose,'.','MarkerSize',1)
        legend('abs coord','reltonose')
        xlabel('PC1')
        ylabel('PC2')
        title('PC of abs and rel coordinates')
    end
    %%% TIME
    figure
    subplot(2,1,1)
    plot(PAW2.Left_x(GIX), '.','Color',GP.Colors.LeftPaw,'MarkerSize',1)
    hold on
    plot(PAW2.Left_y(GIX), '.','Color',GP.Colors.LeftPaw*.7,'MarkerSize',1)
    plot(PAW2.Right_x(GIX),'.','Color',GP.Colors.RightPaw,'MarkerSize',1)
    plot(PAW2.Right_y(GIX),'.','Color',GP.Colors.RightPaw*.7,'MarkerSize',1)
    axis tight
    subplot(2,1,2)
    plot(PAW2.Left_x_to_nose(GIX),'.','Color',GP.Colors.LeftPaw,'MarkerSize',1)
    hold on
    plot(PAW2.Left_y_to_nose(GIX),'.','Color',GP.Colors.LeftPaw*.7,'MarkerSize',1)
    plot(PAW2.Right_x_to_nose(GIX),'.','Color',GP.Colors.RightPaw,'MarkerSize',1)
    plot(PAW2.Right_y_to_nose(GIX),'.','Color',GP.Colors.RightPaw*.7,'MarkerSize',1)
    axis tight
    
    if 0
        figure
        subplot(2,1,1)
        plot(PAW2.PC1(GIX),'.','Color','r','MarkerSize',1)
        hold on
        axis tight
        
        plot(PAW2.PC1tonose(GIX),'.','Color','b','MarkerSize',1)
        subplot(2,1,2)
        plot(PAW2.Dist_Left_to_Right(GIX),'.','Color','b','MarkerSize',1)
        axis tight
    end
end

