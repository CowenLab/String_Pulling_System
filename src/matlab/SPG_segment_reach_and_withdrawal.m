function [SEG,PULLSEG] = SPG_segment_reach_and_withdrawal(POS)
% INPUT: PAW table from DeepLabCut
% OUTPUT:
%        SEG: the POS table but with additional columns added that have the
%        specific paw movements segmented.
%        PULLSEG: additional interval and index data that might be useful.
%
% Adds new information to the PAW table
% NOTE: the raw data - the top point is zero, the bottom point on the
% image is around 900 so up has a first derivative that is negative and
% down is positive.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Cowen 2023.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
n_contig_thr = 25; % this is like 100 msec. It's my choice, but could be looked at systematically. It determines the threshold for a pull up or down.
th_pix = 5; % minimum of vertical distance that must be traversed.
up_th = 0;
PLOT_IT = true;
% reachPhases={'Lift' 'Advance' 'Grasp' 'End'};
% withdrawPhases={'Pull' 'Push' 'End'};

Phases = {'Lift' 'Advance' 'Grasp' 'Pull' 'Push' };
LRstr =  {'Left' 'Right'};

GP = SPG_Globals;
SEG = POS; % rename to ensure we don't confuse the two tables.

phasecats = GP.phase_codes2(:);
phasecats{end+1} = 'uncategorized';

% Determine meaningful events from the paw data.
%% Find a contiguous rise and a contiguous fall.
% GIXall = SEG.good_pull_periods_all & SEG.Right_Paw_y > up_th;
% RIGHT
ALL_GOOD_IX  =  SEG.good_pull_periods_all & abs(SEG.PC1) < 4 & abs(SEG.PC2) < 4;
[~,block_sizes,st,ed]  = Count_contiguous(SEG.Right_Paw_y_d1>0 & SEG.Right_Paw_y > up_th & ALL_GOOD_IX);
% Should do an additional screen to make sure it is truly a start - like
% make sure the phase is where it should be to get rid of bad starts.

% dist from start to end of pull must be postive and above a certain th.
GIX = SEG.Right_Paw_y(ed) - SEG.Right_Paw_y(st) >= th_pix & block_sizes(:) > n_contig_thr ;
PULLSEG.Withdraw.Right.start_end_t_uS = [SEG.Intan_uS(st(GIX)) SEG.Intan_uS(ed(GIX))];
%%%%%%%
[~,block_sizes,st,ed]  = Count_contiguous(SEG.Right_Paw_y_d1<0 & SEG.Right_Paw_y > up_th & ALL_GOOD_IX);
GIX = SEG.Right_Paw_y(ed) - SEG.Right_Paw_y(st) <= -1*th_pix & block_sizes(:) > n_contig_thr;

tmp = [SEG.Intan_uS(st(GIX)) SEG.Intan_uS(ed(GIX))];
durs_sec = diff(tmp,[],2)/1e6;
PULLSEG.Reach.Right.start_end_t_uS = tmp(durs_sec > 0.06 & durs_sec < .4,:);

[~,SEG.Right_Reach_IX] = Restrict(SEG.Intan_uS, PULLSEG.Reach.Right.start_end_t_uS);
[~,SEG.Right_Withdraw_IX] = Restrict(SEG.Intan_uS, PULLSEG.Withdraw.Right.start_end_t_uS);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LEFT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[~,block_sizes,st,ed]  = Count_contiguous(SEG.Left_Paw_y_d1>0 & SEG.Left_Paw_y > up_th & ALL_GOOD_IX);
GIX = SEG.Left_Paw_y(ed) - SEG.Left_Paw_y(st) >= th_pix & block_sizes(:) > n_contig_thr(:) ;
% To be a valid pull, the first derivative in the x should transitiion from
% pos to neg or vice versa.
PULLSEG.Withdraw.Left.start_end_t_uS = [SEG.Intan_uS(st(GIX)) SEG.Intan_uS(ed(GIX))];
%%%%%%%
[~,block_sizes,st,ed]  = Count_contiguous(SEG.Left_Paw_y_d1<0 & SEG.Left_Paw_y > up_th & ALL_GOOD_IX);
GIX = SEG.Left_Paw_y(ed) - SEG.Left_Paw_y(st) <= -1*th_pix & block_sizes(:) > n_contig_thr(:);
tmp = [SEG.Intan_uS(st(GIX)) SEG.Intan_uS(ed(GIX))];
durs_sec = diff(tmp,[],2)/1e6;
PULLSEG.Reach.Left.start_end_t_uS = tmp(durs_sec > 0.06 & durs_sec < .4,:);

[~,SEG.Left_Reach_IX] = Restrict(SEG.Intan_uS, PULLSEG.Reach.Left.start_end_t_uS);
[~,SEG.Left_Withdraw_IX] = Restrict(SEG.Intan_uS, PULLSEG.Withdraw.Left.start_end_t_uS);

txt = {'Left' 'Right'};
for iLR = 1:2
    mean_dur_s =mean(diff(PULLSEG.Withdraw.(txt{iLR}).start_end_t_uS,[],2))/1e6;
    % Merge intervals to get each full cycle.
    for ii = 1:Rows(PULLSEG.Reach.(txt{iLR}).start_end_t_uS)
        st = PULLSEG.Reach.(txt{iLR}).start_end_t_uS(ii,1);
        ix = find(PULLSEG.Withdraw.(txt{iLR}).start_end_t_uS(:,1) > st,1,"first");
        if isempty(ix)
            ed = PULLSEG.Reach.(txt{iLR}).start_end_t_uS(ii,1)+mean_dur_s*1e6;
        else
            ed = PULLSEG.Withdraw.(txt{iLR}).start_end_t_uS(ix,2);
        end
        % Get rid of bad intervals.
        if (ed-st)/1e6 > 1
            ed = PULLSEG.Reach.(txt{iLR}).start_end_t_uS(ii,1)+mean_dur_s*1e6;
        end
        PULLSEG.PullCycle.(txt{iLR}).start_end_t_uS(ii,:) = [st ed];
    end
    % dur_s = (PULLSEG.PullCycle.(txt{iLR}).start_end_t_uS(:,2) -  PULLSEG.PullCycle.(txt{iLR}).start_end_t_uS(:,1))/1e6;
end


% Segment further. Go through each segment in detail and identify the
% different phases.

for iP = 1:length(Phases)
    for iLR = 1:2
        PULLSEG.(Phases{iP}).(LRstr{iLR}).start_end_t_uS = NaN(size(PULLSEG.PullCycle.(LRstr{iLR}).start_end_t_uS));
        PULLSEG.(Phases{iP}).(LRstr{iLR}).row_ix = []; % Rows in the pos table.
        PULLSEG.(Phases{iP}).(LRstr{iLR}).start_end_phase = []; % 
    end
end
% LEFT:
intervals = PULLSEG.PullCycle.Left.start_end_t_uS;
reach_ends = PULLSEG.Reach.Left.start_end_t_uS(:,2);

IV = [PULLSEG.Reach.Left.start_end_t_uS(:,1) PULLSEG.Reach.Left.start_end_t_uS(:,1)+diff(PULLSEG.Reach.Left.start_end_t_uS,[],2)/2];
V =  Restrict([SEG.Intan_uS SEG.Left_Paw_x_d1], IV);
mn_x_d1_start = mean(V(:,2),'omitnan');

% IV = [PULLSEG.Withdraw.Left.start_end_t_uS(:,1) PULLSEG.Withdraw.Left.start_end_t_uS(:,1)+diff(PULLSEG.Withdraw.Left.start_end_t_uS,[],2)/2];
% V =  Restrict([SEG.Intan_uS SEG.Left_Paw_x_d1], IV);
% mn_x_d1_start_withdraw = mean(V(:,2),'omitnan');

BIX = false(Rows(intervals),1);

% time_dx_shfts_uS  = nan(Rows(intervals),1);
% time_max_spd_uS  = nan(Rows(intervals),1);


for iCycle = 1:Rows(intervals)
    % Focus on the reach first...
    [t_cycle,IX_cycle] = Restrict(SEG.Intan_uS,intervals(iCycle,:));
    row_ix_cycle = find(IX_cycle);
    [t,IX] = Restrict(SEG.Intan_uS,[intervals(iCycle,1) reach_ends(iCycle)] );
    %     row_ix = find(IX);
    x =  movmean(SEG.Left_Paw_x(IX),5,'omitnan');
    dx =  movmean(SEG.Left_Paw_x_d1(IX),5,'omitnan');
    dy =  movmean(SEG.Left_Paw_y_d1(IX),5,'omitnan');

    x_cycle =  movmean(SEG.Left_Paw_x(IX_cycle),5,'omitnan');
    dx_cycle =  movmean(SEG.Left_Paw_x_d1(IX_cycle),5,'omitnan');
    dy_cycle =  movmean(SEG.Left_Paw_y_d1(IX_cycle),5,'omitnan');

    %     ph =  movmean(SEG.Left_Paw_phase(IX),5);
    ph =  movmean(SEG.PC1_Left(IX),5);
    spd =  movmean(SEG.Left_Paw_speed(IX),5);
    rat = sum(dx>0)/(sum(dx>0) + sum(dx < 0));
    % check to be sure that there is a transition in the x coordinate
    if rat < .2 || rat > .8 || (sign(mn_x_d1_start) ~= sign(dx(1)))
        BIX(ii) = true;
        continue
    end
    % find point where x transitions.
    [~,ix_spd] = max(spd);
    [~,ix_dx_pk] = findpeaks(dx);
    [~,ix_mx] = max(abs(x - x(1)),[],'omitnan');
    if isempty(ix_dx_pk)
        ix_dx_pk = length(dx);
    end
    %     [~,ix_dx_tr] = findpeaks(dx*-1);
    %     ix_dx_tr(ix_dx_tr < ix_dx_pk(1)) = [];
    ix_dx_chg = find(sign(dx) ~= sign(mn_x_d1_start),1,'first');

    if ix_dx_chg < 10
        %         BIX(iCycle) = true;
        continue
    end
    if isempty(ix_spd) ||  isempty(ix_dx_pk) % ||  isempty(ix_dx_tr)
        %         BIX(iCycle) = true;
        continue
    end

    lift_ix = 1:ix_spd(1);


    if ix_dx_chg(1) >= ix_spd(1)
        advance_ix = (ix_spd(1)):ix_dx_chg(1);
    else
        advance_ix = ix_spd(1)+1;
    end
    if advance_ix(end) >= length(dx)
        advance_ix = length(dx)-1;
        grasp_ix = length(dx);
    else
        grasp_ix = (advance_ix(end)+1):length(dx);
    end
    % Find when y starts decreasing. This is the end of the grasp and start
    % of the pull.
    dy_cycle(isnan(dy_cycle)) = sign(mean(dy,'omitnan'));
    ix = find(t_cycle > t(end) & sign(dy_cycle) ~= sign(mean(dy,'omitnan')),1,'first');
    if isempty(ix)
        continue;
    end
    grasp_ix = grasp_ix(1):ix;
    % From here- figure out the pull and push phases. It is the same idea -
    % when dx changes (and maybe speed?) then we have evidence that the
    % push is starting.
    %     ix = find(t_cycle > t_cycle(grasp_ix(end)+10) & sign(dx_cycle) ~= sign( mn_x_d1_start_withdraw) ,1,'first');
    % Alternative - find point of max X - that would be the transition to
    % release
    end_ix = min([ length(x_cycle) grasp_ix(end)+10]); % deals with the rare exception when the length is not long enough.
    tmp = x_cycle - mean(x_cycle(grasp_ix(end):end_ix)); % recenter.
    end_ix = min([ length(x_cycle) grasp_ix(end)+5]); % deals with the rare exception when the length is not long enough.
    tmp(1:end_ix) = 0;
    [~,ix] = max(abs(tmp),[],'omitnan');
    if isempty(ix)
        pull_ix = grasp_ix(end)+1;
    else
        pull_ix = grasp_ix(end):ix;
    end
    if isempty(pull_ix)
        %         BIX(iCycle) = true;
        continue
    end

    push_ix = (pull_ix(end)+1):length(dx_cycle);
    if isempty(push_ix)
        push_ix = length(dx_cycle);
        pull_ix = pull_ix(1:end-1);
    end
    % This would be a  good place to put othter useful times.
    %     time_dx_shfts_uS(iCycle) = t(ix_dx_chg(1));
    %     time_max_spd_uS(iCycle) = t(ix_spd);

    PULLSEG.Lift.Left.row_ix = [PULLSEG.Lift.Left.row_ix; row_ix_cycle(lift_ix)];
    PULLSEG.Advance.Left.row_ix = [PULLSEG.Advance.Left.row_ix;  row_ix_cycle(advance_ix)];
    PULLSEG.Grasp.Left.row_ix =[PULLSEG.Grasp.Left.row_ix; row_ix_cycle(grasp_ix)];
    PULLSEG.Pull.Left.row_ix = [PULLSEG.Pull.Left.row_ix; row_ix_cycle(pull_ix)];
    PULLSEG.Push.Left.row_ix = [PULLSEG.Push.Left.row_ix; row_ix_cycle(push_ix)];

    % Determine the start and end time of each cycle as well as the phase at
    % start and end.

    vix = row_ix_cycle(lift_ix);
    PULLSEG.Lift.Left.start_end_t_uS(iCycle,:) = SEG.Intan_uS(vix([1 end]))';
    PULLSEG.Lift.Left.start_end_phase(iCycle,:) = SEG.Left_Paw_phase(vix([1 end]))';

    vix = row_ix_cycle(advance_ix);
    PULLSEG.Advance.Left.start_end_t_uS(iCycle,:) = SEG.Intan_uS(vix([1 end]))';
    PULLSEG.Advance.Left.start_end_phase(iCycle,:) = SEG.Left_Paw_phase(vix([1 end]))';

    vix = row_ix_cycle(grasp_ix);
    PULLSEG.Grasp.Left.start_end_t_uS(iCycle,:) = SEG.Intan_uS(vix([1 end]))';
    PULLSEG.Grasp.Left.start_end_phase(iCycle,:) = SEG.Left_Paw_phase(vix([1 end]))';

    vix = row_ix_cycle(pull_ix);
    PULLSEG.Pull.Left.start_end_t_uS(iCycle,:) = SEG.Intan_uS(vix([1 end]))';
    PULLSEG.Pull.Left.start_end_phase(iCycle,:) = SEG.Left_Paw_phase(vix([1 end]))';

    vix = row_ix_cycle(push_ix);
    PULLSEG.Push.Left.start_end_t_uS(iCycle,:) = SEG.Intan_uS(vix([1 end]))';
    PULLSEG.Push.Left.start_end_phase(iCycle,:) = SEG.Left_Paw_phase(vix([1 end]))';



    % Create a 'normalized' trajectory such that x and y are normalized to
    % the start of each pull

    xt = 1:length(dx);
    xc = 1:length(dx_cycle);
    px =  SEG.Left_Paw_x(IX);
    py =  SEG.Left_Paw_y(IX);
    px = px - px(1);
    py = py - py(1);

    pxc =  SEG.Left_Paw_x(IX_cycle);
    pyc =  SEG.Left_Paw_y(IX_cycle);
    %     pxc = pxc - pxc(1);
    %     pyc = pyc - pyc(1);
    pxc = pxc - mean(pxc);
    pyc = pyc - mean(pyc);


    SEG.Left_Paw_Cyc_norm_x(IX_cycle) = pxc;
    SEG.Left_Paw_Cyc_norm_y(IX_cycle) = pyc;
    SEG.Left_Paw_Cyc_ID(IX_cycle) = iCycle;

    %

    if PLOT_IT

        if iCycle == 1
            figure;
        end
        subplot(2,3,1)
        plot(xc(lift_ix),dx_cycle(lift_ix),'r',xc(advance_ix),dx_cycle(advance_ix),'g',xc(grasp_ix),dx_cycle(grasp_ix),'b',xc(pull_ix),dx_cycle(pull_ix),'m')
        hold on
        pubify_figure_axis
        xlabel('pixel');
        subplot(2,3,2)
        plot(ph)
        hold on
        subplot(2,3,3)
        plot(spd)
        hold on
        subplot(2,3,4)
        plot(pxc(lift_ix),pyc(lift_ix),'r',pxc(advance_ix),pyc(advance_ix),'g',pxc(grasp_ix),pyc(grasp_ix),'b',pxc(pull_ix),pyc(pull_ix),'m',pxc(push_ix),pyc(push_ix),'c')
        hold on
        subplot(2,3,5)
        spdc =  movmean(SEG.Left_Paw_speed(IX_cycle),5)';
        plot(xc(lift_ix),spdc(lift_ix),'r',xc(advance_ix),spdc(advance_ix),'g',xc(grasp_ix),spdc(grasp_ix),'b',xc(pull_ix),spdc(pull_ix),'m',xc(push_ix),spdc(push_ix),'c')
        hold on
    end
end
if PLOT_IT
    subplot(2,3,4)
    axis ij
    pubify_figure_axis
    xlabel('pixel');ylabel('pixel')
    legend_color_text({'L' 'A' 'G' 'PL' 'PSH'}, {'r' 'g' 'b' 'm' 'c'})
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RIGHT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
intervals = PULLSEG.PullCycle.Right.start_end_t_uS;
reach_ends = PULLSEG.Reach.Right.start_end_t_uS(:,2);

IV = [PULLSEG.Reach.Right.start_end_t_uS(:,1) PULLSEG.Reach.Right.start_end_t_uS(:,1)+diff(PULLSEG.Reach.Right.start_end_t_uS,[],2)/2];
V =  Restrict([SEG.Intan_uS SEG.Right_Paw_x_d1], IV);
mn_x_d1_start = mean(V(:,2),'omitnan');

% IV = [PULLSEG.Withdraw.Right.start_end_t_uS(:,1) PULLSEG.Withdraw.Right.start_end_t_uS(:,1)+diff(PULLSEG.Withdraw.Right.start_end_t_uS,[],2)/2];
% V =  Restrict([SEG.Intan_uS SEG.Right_Paw_x_d1], IV);
% mn_x_d1_start_withdraw = mean(V(:,2),'omitnan');

BIX = false(Rows(intervals),1);

% time_dx_shfts_uS  = nan(Rows(intervals),1);
% time_max_spd_uS  = nan(Rows(intervals),1);


for iCycle = 1:Rows(intervals)
    % Focus on the reach first...
    [t_cycle,IX_cycle] = Restrict(SEG.Intan_uS,intervals(iCycle,:));
    row_ix_cycle = find(IX_cycle);
    [t,IX] = Restrict(SEG.Intan_uS,[intervals(iCycle,1) reach_ends(iCycle)] );
    %     row_ix = find(IX);
    x =  movmean(SEG.Right_Paw_x(IX),5);
    dx =  movmean(SEG.Right_Paw_x_d1(IX),5);
    dy =  movmean(SEG.Right_Paw_y_d1(IX),5);

    x_cycle =  movmean(SEG.Right_Paw_x(IX_cycle),5);
    dx_cycle =  movmean(SEG.Right_Paw_x_d1(IX_cycle),5);
    dy_cycle =  movmean(SEG.Right_Paw_y_d1(IX_cycle),5);

    %     ph =  movmean(SEG.Right_Paw_phase(IX),5);
    ph =  movmean(SEG.PC1_Right(IX),5);
    spd =  movmean(SEG.Right_Paw_speed(IX),5);
    rat = sum(dx>0)/(sum(dx>0) + sum(dx < 0));
    % check to be sure that there is a transition in the x coordinate
    if rat < .2 || rat > .8 || (sign(mn_x_d1_start) ~= sign(dx(1)))
        BIX(ii) = true;
        continue
    end
    % find point where x transitions.
    [~,ix_spd] = max(spd);
    [~,ix_dx_pk] = findpeaks(dx);
    [~,ix_mx] = max(abs(x - x(1)),[],'omitnan');
    if isempty(ix_dx_pk)
        ix_dx_pk = length(dx);
    end
    %     [~,ix_dx_tr] = findpeaks(dx*-1);
    %     ix_dx_tr(ix_dx_tr < ix_dx_pk(1)) = [];
    ix_dx_chg = find(sign(dx) ~= sign(mn_x_d1_start),1,'first');

    if ix_dx_chg < 10
        BIX(iCycle) = true;
        continue
    end
    if isempty(ix_spd) ||  isempty(ix_dx_pk) % ||  isempty(ix_dx_tr)
        BIX(iCycle) = true;
        continue
    end

    lift_ix = 1:ix_spd(1);


    if ix_dx_chg(1) >= ix_spd(1)
        advance_ix = (ix_spd(1)):ix_dx_chg(1);
    else
        advance_ix = ix_spd(1)+1;
    end

    if advance_ix(end) >= length(dx)
        advance_ix = length(dx)-1;
        grasp_ix = length(dx);
    else
        grasp_ix = (advance_ix(end)+1):length(dx);
    end
    % Find when y starts decreasing. This is the end of the grasp and start
    % of the pull.
    dy_cycle(isnan(dy_cycle)) = sign(mean(dy,'omitnan'));
    ix = find(t_cycle > t(end) & sign(dy_cycle) ~= sign(mean(dy,'omitnan')),1,'first');
    grasp_ix = grasp_ix(1):ix;
    % From here- figure out the pull and push phases. It is the same idea -
    % when dx changes (and maybe speed?) then we have evidence that the
    % push is starting.
    %     ix = find(t_cycle > t_cycle(grasp_ix(end)+10) & sign(dx_cycle) ~= sign( mn_x_d1_start_withdraw) ,1,'first');
    % Alternative - find point of max X - that would be the transition to
    % release
    if isempty(grasp_ix)
        % this imigth be a bad idea
        continue
    end
    ixmin = min([length(x_cycle) grasp_ix(end)+5]);
    tmp = x_cycle - mean(x_cycle(grasp_ix(end):ixmin)); % recenter.
    tmp(1:(grasp_ix(end)+5)) = 0;
    [~,ix] = max(abs(tmp),[],'omitnan');
    if isempty(ix)
        pull_ix = grasp_ix(end)+1;
    else
        pull_ix = grasp_ix(end):ix;
    end
    if isempty(pull_ix)
        %         BIX(iCycle) = true;
        continue
    end
    push_ix = (pull_ix(end)+1):length(dx_cycle);
    if isempty(push_ix)
        push_ix = length(dx_cycle);
        pull_ix = pull_ix(1:end-1);
    end
    % This would be a  good place to put othter useful times.
    %     time_dx_shfts_uS(iCycle) = t(ix_dx_chg(1));
    %     time_max_spd_uS(iCycle) = t(ix_spd);

    PULLSEG.Lift.Right.row_ix = [PULLSEG.Lift.Right.row_ix; row_ix_cycle(lift_ix)];
    PULLSEG.Advance.Right.row_ix = [PULLSEG.Advance.Right.row_ix;  row_ix_cycle(advance_ix)];
    PULLSEG.Grasp.Right.row_ix =[PULLSEG.Grasp.Right.row_ix; row_ix_cycle(grasp_ix)];
    PULLSEG.Pull.Right.row_ix = [PULLSEG.Pull.Right.row_ix; row_ix_cycle(pull_ix)];
    PULLSEG.Push.Right.row_ix = [PULLSEG.Push.Right.row_ix; row_ix_cycle(push_ix)];

    % Determine the start and end time of each cycle as well as the phase at
    % start and end.

    vix = row_ix_cycle(lift_ix);
    PULLSEG.Lift.Right.start_end_t_uS(iCycle,:) = SEG.Intan_uS(vix([1 end]))';
    PULLSEG.Lift.Right.start_end_phase(iCycle,:) = SEG.Right_Paw_phase(vix([1 end]))';

    vix = row_ix_cycle(advance_ix);
    PULLSEG.Advance.Right.start_end_t_uS(iCycle,:) = SEG.Intan_uS(vix([1 end]))';
    PULLSEG.Advance.Right.start_end_phase(iCycle,:) = SEG.Right_Paw_phase(vix([1 end]))';

    vix = row_ix_cycle(grasp_ix);
    PULLSEG.Grasp.Right.start_end_t_uS(iCycle,:) = SEG.Intan_uS(vix([1 end]))';
    PULLSEG.Grasp.Right.start_end_phase(iCycle,:) = SEG.Right_Paw_phase(vix([1 end]))';

    vix = row_ix_cycle(pull_ix);
    PULLSEG.Pull.Right.start_end_t_uS(iCycle,:) = SEG.Intan_uS(vix([1 end]))';
    PULLSEG.Pull.Right.start_end_phase(iCycle,:) = SEG.Right_Paw_phase(vix([1 end]))';

    vix = row_ix_cycle(push_ix);
    PULLSEG.Push.Right.start_end_t_uS(iCycle,:) = SEG.Intan_uS(vix([1 end]))';
    PULLSEG.Push.Right.start_end_phase(iCycle,:) = SEG.Right_Paw_phase(vix([1 end]))';

    xt = 1:length(dx);
    xc = 1:length(dx_cycle);
    px =  SEG.Right_Paw_x(IX);
    py =  SEG.Right_Paw_y(IX);
    px = px - px(1);
    py = py - py(1);

    pxc =  SEG.Right_Paw_x(IX_cycle);
    pyc =  SEG.Right_Paw_y(IX_cycle);
    %     pxc = pxc - pxc(1);
    %     pyc = pyc - pyc(1);
    pxc = pxc - mean(pxc);
    pyc = pyc - mean(pyc);



    SEG.Right_Paw_Cyc_norm_x(IX_cycle) = pxc;
    SEG.Right_Paw_Cyc_norm_y(IX_cycle) = pyc;
    SEG.Right_Paw_Cyc_ID(IX_cycle) = iCycle;
    %

    if PLOT_IT
        if iCycle == 1
            figure;
        end
        subplot(2,3,1)
        plot(xc(lift_ix),dx_cycle(lift_ix),'r',xc(advance_ix),dx_cycle(advance_ix),'g',xc(grasp_ix),dx_cycle(grasp_ix),'b',xc(pull_ix),dx_cycle(pull_ix),'m')
        hold on
        subplot(2,3,2)
        plot(ph)
        hold on
        subplot(2,3,3)
        plot(spd)
        hold on
        subplot(2,3,4)
        plot(pxc(lift_ix),pyc(lift_ix),'r',pxc(advance_ix),pyc(advance_ix),'g',pxc(grasp_ix),pyc(grasp_ix),'b',pxc(pull_ix),pyc(pull_ix),'m',pxc(push_ix),pyc(push_ix),'c')
        hold on
        axis ij
        subplot(2,3,5)
        spdc =  movmean(SEG.Right_Paw_speed(IX_cycle),5)';
        plot(xc(lift_ix),spdc(lift_ix),'r',xc(advance_ix),spdc(advance_ix),'g',xc(grasp_ix),spdc(grasp_ix),'b',xc(pull_ix),spdc(pull_ix),'m',xc(push_ix),spdc(push_ix),'c')
        hold on
    end
end
SEG.Left_Paw_Cyc_norm_x(SEG.Left_Paw_Cyc_norm_x == 0) = nan;
SEG.Left_Paw_Cyc_norm_y(SEG.Left_Paw_Cyc_norm_y == 0) = nan;
SEG.Left_Paw_Cyc_ID(SEG.Left_Paw_Cyc_ID == 0) = nan;

SEG.Right_Paw_Cyc_norm_x(SEG.Right_Paw_Cyc_norm_x == 0) = nan;
SEG.Right_Paw_Cyc_norm_y(SEG.Right_Paw_Cyc_norm_y == 0) = nan;
SEG.Right_Paw_Cyc_ID(SEG.Right_Paw_Cyc_ID == 0) = nan;

SEG.Left_Paw_Cyc_ID = int8(SEG.Left_Paw_Cyc_ID);
SEG.Right_Paw_Cyc_ID = int8(SEG.Right_Paw_Cyc_ID);


% Add the segmented data to the POS table.
% This is all so stupid. Get it together matlab.
PullPhaseLeft = cell(size(SEG.Intan_uS(:)));
[PullPhaseLeft{:}] = deal('uncategorized');
[PullPhaseLeft{PULLSEG.Advance.Left.row_ix}] = deal('advance');
[PullPhaseLeft{PULLSEG.Grasp.Left.row_ix}] = deal('grasp');
[PullPhaseLeft{PULLSEG.Lift.Left.row_ix}] = deal('lift');
[PullPhaseLeft{PULLSEG.Pull.Left.row_ix}] = deal('pull');
[PullPhaseLeft{PULLSEG.Push.Left.row_ix}] = deal('push');
PullPhaseLeft = categorical(PullPhaseLeft);

% Right
PullPhaseRight = cell(size(SEG.Intan_uS(:)));
[PullPhaseRight{:}] = deal('uncategorized');
[PullPhaseRight{PULLSEG.Advance.Right.row_ix}] = deal('advance');
[PullPhaseRight{PULLSEG.Grasp.Right.row_ix}] = deal('grasp');
[PullPhaseRight{PULLSEG.Lift.Right.row_ix}] = deal('lift');
[PullPhaseRight{PULLSEG.Pull.Right.row_ix}] = deal('pull');
[PullPhaseRight{PULLSEG.Push.Right.row_ix}] = deal('push');
PullPhaseRight = categorical(PullPhaseRight);

PullPhaseLeft = reordercats(PullPhaseLeft,phasecats);
PullPhaseRight = reordercats(PullPhaseRight,phasecats);

SEG = addvars(SEG,PullPhaseLeft);
SEG = addvars(SEG,PullPhaseRight);
%% Find the MEDIAN start phase and end phase for each of the categorical reach segnment
%  This is very useful for plotting - gives something to lable.
for iLR = 1:2
    for iP = 1:length(Phases)
        s = PULLSEG.(Phases{iP}).(LRstr{iLR}).start_end_phase(:,1);
        e = PULLSEG.(Phases{iP}).(LRstr{iLR}).start_end_phase(:,end);
        s = s(~isnan(s)); e = e(~isnan(e));
        s = s(s~=0); e = e(e ~= 0);
        PULLSEG.(Phases{iP}).(LRstr{iLR}).start_end_phase_median(1) = circ_median(s);
        PULLSEG.(Phases{iP}).(LRstr{iLR}).start_end_phase_median(2) = circ_median(e);
    end
end

% for iLR = 1:2
%     for iP = 1:length(Phases)
%         PULLSEG.(Phases{iP}).(LRstr{iLR}).start_end_phase_median
%     end
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate nice figures for the publications.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if PLOT_IT    % Just reach and withdraw


    % PCA:
    figure
    subplot(1,2,1)
    plot(SEG.PC1_Left(ALL_GOOD_IX),SEG.PC2_Left(ALL_GOOD_IX),'.','Color',GP.Colors.RightPaw,'MarkerSize',1)
    hold on
    plot(SEG.PC1_Left(SEG.Left_Reach_IX),SEG.PC2_Left(SEG.Left_Reach_IX),'.','Color','r','MarkerSize',2)
    plot(SEG.PC1_Left(SEG.Left_Withdraw_IX),SEG.PC2_Left(SEG.Left_Withdraw_IX),'.','Color','b','MarkerSize',2)
    title('Left Paw');ylabel('pixels');xlabel('pixels')
    axis ij
    pubify_figure_axis

    subplot(1,2,2)
    plot(SEG.PC1_Right(ALL_GOOD_IX),SEG.PC2_Right(ALL_GOOD_IX),'.','Color',GP.Colors.RightPaw,'MarkerSize',1)
    hold on
    plot(SEG.PC1_Right(SEG.Right_Reach_IX),SEG.PC2_Right(SEG.Right_Reach_IX),'.','Color','r','MarkerSize',2)
    plot(SEG.PC1_Right(SEG.Right_Withdraw_IX),SEG.PC2_Right(SEG.Right_Withdraw_IX),'.','Color','b','MarkerSize',2)
    title('Right Paw');ylabel('pixels');xlabel('pixels')
    axis ij % because up is down and down is up on the video
    pubify_figure_axis
    set(gcf,'Position',[314 176 836 554])
    sgtitle(pwd)


    % Each pull aligned
    LRstr = {'Left' 'Right'} ;
    RWstr = {'Reach' 'Withdraw'};
    clrs = {'r' 'b'};
    figure
    for iLR = 1:2
        subplot(1,2,iLR)
        for iRW = 1:2
            intervals = PULLSEG.(RWstr{iRW}).(LRstr{iLR}).start_end_t_uS;
            for ii = 1:Rows(intervals)
                [~,IX] = Restrict(SEG.Intan_uS,intervals(ii,:));
                xy = [SEG.([LRstr{iLR} '_Paw_x'])(IX) SEG.([LRstr{iLR} '_Paw_y'])(IX)];
                %                 xy = [SEG.(['PC1_' LRstr{iLR} ])(IX) SEG.(['PC2_' LRstr{iLR}])(IX)];
                xy = xy - repmat(xy(1,:), Rows(xy),1);
                plot(xy(:,1),xy(:,2),'-','Color', clrs{iRW})
                hold on
            end
            axis ij
            yyaxis right
        end
        title(LRstr{iLR})
        pubify_figure_axis
    end
    equalize_axes
    legend_color_text(RWstr,clrs);
    xlabel('pixels')
    set(gcf,'Position',[314 176 1016 639])
    sgtitle(pwd)


end
