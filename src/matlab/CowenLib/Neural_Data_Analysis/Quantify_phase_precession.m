function phase = Quantify_phase_precession(phase, alignment_angle, x_to_use, burst_threshold_msec, maze_pass_duration_limit_msec);
% function phase = Quantify_precession(phase, alignment_angle);
% 
% INPUT: a structure phase with the folowing elements:
%     spike_times_ts - the timestamps in the spike train.
%     phase.phase_id - an integer from 1-4. Each cycle is divided in 4 sections and phase ID
%                   corresponds to each of these segments.
%     phase.quarter_phase_time - Time of the nearest peak, zero cross, or trough.
%     phase.phase_count - Count of the phase (4 increments per phase then it starts again with a 1).
%     phase.cycle_count - Count of the cycles(4 counts per cycle.) starting from 1.
%     phase.ph_count_linked_to_phase - interpolated phase count. 
%     phase.interp_phasetime - the interpolated time (ts). Finds the spike time and then add 
%     phase.phase_angle - a number from 0 to 1 that specifies the phase angle (0 - 360 degrees).
%     phase.ZA_spikes - spike times for each run through the PF starting from the first spike.
%     phase.CA_spikes - CA spikes: are counted in phase counts (4/cycle) starting from 0. They are interpolated.
%                    For example, if the spike occured between phase count 43 and 44 then 
%                    the ZA spike would be 43.5.
%     phase.pass_no   - Keeps track of the pass through the PF.
%     phase.phase_angle 
%
%  alignment_angle - the angle as measured as a value from 0-1. This shifts the data by this
%     amount (useful because the first spike in a pass does not align to the peak of theta.
%  maze_pass_duration_limit_msec - Amount to limit the duration of one pass with the start defined as the time of the first spike 
%     through a place field. Ignore stuff that occurs later.
%
% OUTPUT:
%  A structure phase that contains the original structure in phase with the folowing fields added.
%   phase.x_to_use - which x value to use: 'cycle_aligned', 'time', 'position'.
%   phase.p - p value from running through the regression and determining if the R is significant. 
%   phase.Rsq - the R^2 value
%   phase.slope - the slope of the ls line.
%   phase.intercept - the intercept of the ls line.
%   phase.pass_angle_diffs - the difference in phase angle between successive spikes. phaselot the 
%     histogram of these angles to determine if it is different from 0.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3
    x_to_use = 'time_msec';
end
if nargin < 4
    burst_threshold_msec = 45;
end
min_spikes_per_burst = 1;

if nargin < 5
    maze_pass_duration_limit_msec = 2000; % Amount to limit the duration of one pass 
    % through a place field. Ignore stuff that occurs later.
end

 
    phase.intercept = [];
    phase.slope     = [];
    phase.Rsq = []; 
    phase.p   = []; % significance of the regression. Is it different from 0?
    phase.slope_1st = [];
    phase.Rsq_1st = [];
    phase.p_1st = [];
    phase.pass_angle_diffs = [];
    phase.angle_diffs_bias =[];
 
if isempty(phase.time) | length(phase.time) < 5
    disp('NO or NOT ENOUGH spikes.')
    return
end

switch x_to_use
case 'cycle_aligned'
    x = phase.CA_spikes;
case 'time_msec'
    x = phase.ZA_spikes/10; % Convert to msec
case 'position'
    disp ('not implemented')
    x = phase.PA_spikes; % Not implemented yet.
otherwise
    error('incorrect x');
end
phase.x_to_use = x_to_use;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get rid of spikes that occor over maze_pass_duration_limit_msec after the first spike.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
idx = find(phase.ZA_spikes/10 < maze_pass_duration_limit_msec);
x = x(idx);
spike_times_ts  = phase.time(idx);
phase_angle     = phase.phase_angle(idx);
pass_no         = phase.pass_no(idx);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Re-align the phase angle by some user specified amount.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pa = phase_angle + alignment_angle;
pa (find(pa > 1)) = pa (find(pa > 1)) - 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Note: I considered treating each pass as an unique event and then computing the 
%  average over these passes. It turns out a regression on the entire data set is
%  more powerful.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Identify the first spike of a burst. It is these spikes that seem to precess 
% the most.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[first_in_burst, durations, n_per_burst, burst_id] = Burst_detector(spike_times_ts, burst_threshold_msec*10, min_spikes_per_burst);
first_idx = zeros(length(first_in_burst),1)*nan;
for ii = 1:length(first_in_burst)
    first_idx(ii) = find(spike_times_ts==first_in_burst(ii));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine which x to use (real time, poistion, cycle time)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[b,bint,r,rint,stats] = regress(pa,[ones(length(x),1) x]);
% y = Xb
phase.intercept = b(1);
phase.slope     = b(2);
phase.Rsq = stats(1); 
phase.p   = stats(3); % significance of the regression. Is it different from 0?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% It's possible that the first spike on each cycle may show more precession than the rest.
%  this seems to be true when eyballing the data. To address this, 
if length(first_idx) < 3
    disp ('too few spikes for 1st spike analysis')
    phase.intercept_1st = nan;
    phase.slope_1st     = nan;
    phase.Rsq_1st = nan; 
    phase.p_1st   = nan;   % significance of the regression. Is it different from 0?
else
    [b,bint,r,rint,stats] = regress(pa(first_idx),[ones(length(x(first_idx)),1) x(first_idx)]);
    phase.intercept_1st = b(1);
    phase.slope_1st     = b(2);
    phase.Rsq_1st = stats(1); 
    phase.p_1st   = stats(3);   % significance of the regression. Is it different from 0?
end  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine the difference in phase angle between successive spikes on a given pass.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
phase.pass_angle_diffs = [];
for pass = unique(pass_no)'
    idx = find(pass_no == pass);
    phase.pass_angle_diffs = [ phase.pass_angle_diffs; diff(pa(idx))];
end
idxl = find(phase.pass_angle_diffs<-.2);
idxr = find(phase.pass_angle_diffs<-.2);
if isempty(idxl)
    ml = 0;
else
    ml = mean(phase.pass_angle_diffs(idxr));
end
if isempty(idxr)
    mr = 0;
else
    mr = mean(phase.pass_angle_diffs(idxr));
end

phase.angle_diffs_bias = (abs(ml) - abs(mr))/(abs(ml) + abs(mr));


if nargout == 0
    %subplot(2,4,[1 2 3 5 6 7]);
    %g=gscatter(x,pa,pass_no,[],[],[],0); % screws up subplots
    m = colormap;
    colormap (prism)
    cm = colormap;
    colormap(m);
    crows = floor(linspace(1,Rows(cm),length(unique(pass_no))));
    count = 1;
    for pass = unique(pass_no)'
        idx = find(pass_no == pass);
        plot(x(idx),pa(idx),'.','Color',cm(crows(count),:),'MarkerSize',14)
        hold on
        count = count + 1;
    end
    plot(x(first_idx) , pa(first_idx), 'or','MarkerSize',3)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Sliding Mode and Min. Go step by step and compute the local mode and local min.
    % Finds local averages for the value pa over intervals of size dt and shifts by intervals of shift.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %[smean,smode,smax,smin,sstd] = Sliding_stats(x,pa,dt,shift); 
   
    %pf = polyfit(x,pa,1);
    %estimate = polyval(pf , x);
    %M = sortrows([x, estimate]);
    %plot( M(:,1) , M(:,2) , 'b')
    a = axis;
    
    plot( [ 0 ; a(2) ] , [ phase.intercept ; phase.intercept + phase.slope*a(2) ] , 'b')
    plot( [ 0 ; a(2) ] , [ phase.intercept_1st ; phase.intercept_1st + phase.slope_1st*a(2) ] , 'r')
    a(3) = 0;
    a(4) = 1;
    a(1) = 0;
    a(2) = maze_pass_duration_limit_msec;
    axis(a);
    grid on
    title_string = [' p = ' sprintf('%0.3f',phase.p) ',  p_1st = ' sprintf('%0.3f',phase.p_1st)];
    title(title_string)
    xlabel(phase.x_to_use)
    ylabel('Angle (0-1)')
    drawnow
end
