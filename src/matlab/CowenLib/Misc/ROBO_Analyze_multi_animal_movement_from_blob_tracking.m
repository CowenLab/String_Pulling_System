%% Analyse movement from simultaneously tracked animals.
% Choose the tracking file. Most other things should not need to be
% changed.
%%%%%%%%%%%%%%%%%%
% tracking_file = 'C:\Users\cowen\Dropbox\tmp\tracker_file.txt';
% tracking_file = 'G:\Cowen\Data\MASTER_TRACKING_FILE.txt';
tracking_file = 'C:\Users\cowen\Dropbox\CowenLab\!Projects\Epilepsy_Mouse_Hammer\Data\tracking_5_4_16j.txt';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% xxyy_box_for_each_animal = [0 90 75 180; 90 180 75 180; 90 180 0 75; 0 90 0 75]; % the center of the maze: required for parsing out the different animals.
xxyy_box_for_each_animal = []; % If this is empty, then the user specifies the bounds of the box for each zone.
% xxyy_box_for_each_animal = [ ...
%     25.5069124423963          56.6129032258064          95.9912536443149          139.285714285714; ...
%     131.267281105991          160.299539170507          109.548104956268          145.408163265306; ...
%     135.829493087558          165.276497695853          2.40524781341108          41.7638483965015; ...
%     21.3594470046083          51.6359447004608          4.59183673469389          41.3265306122449];% 
xxyy_box_for_each_animal = [ ...
    114          0          102          208; ...
    114          208          102          208; ...
    114          0          102          1; ...
    114          208          102          0 ];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
position_smooth_factor_frames = 10;
% Read in the data
fp = fopen(tracking_file,'r');
header = fgetl(fp); % skip the header
M = textscan(fp,'%f %s %f %f %f %f %f %f %f %f','Delimiter',{',' ';'});
fclose(fp);
%% Analysis
t_sec = double(M{1});
% Find good intervals
min_streak_length = 30; % 2 sec about.
min_diff_sec = .5;

new_t_sec = t_sec(1):.05:t_sec(end); % 20 frames/sec should be fine.
new_vel = zeros(size(new_t_sec))*nan;
% Identify good periods (where there are say at least 2 seconds worth of
% samples sampled at a miniumum of 10 samples per second. Mark the non-good
% periods with NANs.

% once these blokcs are identified, perform smoothing within each block to
% get rid of jitter.

% Break the data into chunks incase the time of day has changed.

ALL = [M{3} M{4} M{5} M{6} M{7} M{8} M{9} M{10}];
prs = [1:2;3:4;5:6;7:8];

figure(101)
clf
clrs = lines(size(prs,1));
for iP = 1:size(prs,1)
    plot(ALL(1:10:end,prs(iP,1)),ALL(1:10:end,prs(iP,2)),'.','MarkerSize',2,'Color',clrs(iP,:))
    hold on
end
if isempty(xxyy_box_for_each_animal)
    for ii = 1:4
        title(['INPUT THE 2 BOUNDS of the SQUARE identifying ZONE ' num2str(ii)])
        [x,y] = ginput(2);
        xxyy_box_for_each_animal(ii,:) = [min(x) max(x) min(y) max(y)];
    end
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iMouse = 1:Rows(xxyy_box_for_each_animal);
    MOUSExy{iMouse} = [];
    for ii = 1:size(prs,1)
        IX = ALL(:,prs(ii,1)) > min(xxyy_box_for_each_animal(iMouse,1:2)) & ALL(:,prs(ii,1)) < max(xxyy_box_for_each_animal(iMouse,1:2)) & ...
            ALL(:,prs(ii,2)) > min(xxyy_box_for_each_animal(iMouse,3:4)) & ALL(:,prs(ii,2)) < max(xxyy_box_for_each_animal(iMouse,3:4));
        MOUSExy{iMouse} = [MOUSExy{iMouse};t_sec(IX) ALL(IX,prs(ii,:))];
    end
    MOUSExy{iMouse} = sortrows(MOUSExy{iMouse});
    [IX,ix_start_end] = Find_intervals_by_time(MOUSExy{iMouse}(:,1),min_streak_length,min_diff_sec);
    MOUSExy{iMouse} =  MOUSExy{iMouse}(IX,:);
    % remove any strange repeated timepoints.
    ix = find(diff( MOUSExy{iMouse}(:,2))== 0);
    cnt = 0;
    while(~isempty(ix))
        MOUSExy{iMouse}(ix,:) = [];
        ix = find(diff( MOUSExy{iMouse}(:,2))== 0);
        cnt = cnt + 1;
    end
    %     cnt
    % For each of the intervals of good recs, go through and smooth and interpolate these
    % data.
    for iI = 1:Rows(ix_start_end)
        % Do smoothing here.
    end
end

%% Dots for position
figure(1)
clf
for iM = 1:length(MOUSExy)
    subplot(2,2,iM)
    plot(MOUSExy{iM}(:,2),MOUSExy{iM}(:,3),'k.','MarkerSize',2)
    axis tight
    if iM == 1
        title(['M1 Occ ' M{2}{1} ' to ' M{2}{end}  ' pts' num2str(length(~isnan(MOUSExy{iM}(:,2)))) ] )
        
    else
        title(['Mouse ' num2str(iM) ' pts' num2str(length(~isnan(MOUSExy{iM}(:,2))))])
    end
end

% Heat maps
figure(2)
clf
for iM = 1:length(MOUSExy)
    subplot(2,2,iM)
    V = MOUSExy{iM};
    %     V(:,2) = medfilt1(V(:,2),10);
    %     V(:,3) = medfilt1(V(:,3),10);
    H2 = hist2_harris(V(:,2:3), 80,80);
    H2 = log(H2);
    H2s = conv2(H2,hanning(5)*hanning(5)');
    imagesc(H2s')
    if iM == 1
        title(['M1 Occ ' M{2}{1} ' to ' M{2}{end}] )
        
    else
        title(['Mouse ' num2str(iM)])
    end
    axis xy
    axis tight
end

%% Movement
figure(3)
clf
a = zeros(1,length(MOUSExy));
for iM = 1:length(MOUSExy)
   
    a(iM) = subplot(4,1,iM);
    plot(MOUSExy{iM}(:,1)/3600,MOUSExy{iM}(:,2),'.',MOUSExy{iM}(:,1)/3600,MOUSExy{iM}(:,3),'.')
    axis tight
    ylabel('x or y coord')
    xlabel('min')
    title(['Mouse ' num2str(iM)])
    
end
equalize_axes(a)
subplot(4,1,1)
title([M{2}{1} ' to ' M{2}{end}] )
%%
figure(4)
clf
a = zeros(1,length(MOUSExy));
for iM = 1:length(MOUSExy)

    velx = [0; diff(MOUSExy{iM}(:,2))./diff(MOUSExy{iM}(:,1))];
    vely = [0; diff(MOUSExy{iM}(:,3))./diff(MOUSExy{iM}(:,1))];
    a(iM) = subplot(4,1,iM);
    plot(MOUSExy{iM}(:,1)/3600,abs(velx),'.',MOUSExy{iM}(:,1)/3600,abs(vely),'.')
    axis tight
    ylabel('Speed')
    title(['Mouse ' num2str(iM)])
end
xlabel('Hrs')
equalize_axes(a)
subplot(4,1,1)
title([M{2}{1} ' to ' M{2}{end}] )