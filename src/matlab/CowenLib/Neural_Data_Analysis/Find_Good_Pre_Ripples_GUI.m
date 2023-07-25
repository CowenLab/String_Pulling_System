function pre_rip_intervals = Find_Good_Pre_Ripples_GUI(LFP, riptimes)
%function pre_rip_intervals = Find_Good_Pre_Ripples_GUI(LFP, riptimes)
% Find a pre-ripple interval and choose a noise free region before the
% ripple to grab.
%
% INPUT: LFP - nsamples x 2
%        ripltimes = nrips x 2
%
% OUTPUT: nprerips x 2 
%
% Cowen 2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Create some fake data to test the code (this is JUST for testing - delete these lines when done with testing)...
LFP = zeros(10000,2);
LFP(:,1) = linspace(1,10e6,10000);
LFP(:,2) = rand(10000,1);
riptimes = [ 2e6 2.2e6; 3e6 3.1e6];

% 
% Determine the intervals between datapoints.
sample_interval_usec = median(diff(LFP(:,1)));
% Number of points before to grab (1 sec)
n_pts_before_to_get = round(1e6/sample_interval_usec);

%plot(LFP(:,1),LFP(:,2))
x = zeros(Rows(riptimes));
for iRip = 1:Rows(riptimes)
    % Find the ripple start time.
    ix = find(LFP(:,1) >= riptimes(iRip,1), 1,'first');
    % Find the range of times to get.
    all_ix = (ix-n_pts_before_to_get):(ix+n_pts_before_to_get);
    % Clear the figure window
    clf
    plot(LFP(all_ix,1),LFP(all_ix,2))
    hold on
    % Plot a vertical line to mark the start and end of the ripple.
    a = axis;
    plot([riptimes(iRip,1) riptimes(iRip,1) ],a(3:4),'r:')
    plot([riptimes(iRip,2) riptimes(iRip,2) ],a(3:4),'g:')
    [x(iRip,:), y] = ginput(2); % GUI crosshairs for grabbing an interval of timestamps
    % Check if the user clicked to the left of the figure - this indicates
    % that this was a BAD sample point. If it's bad, label it with nans
    if x(iRip,1) < a(1) || x(iRip,2) < a(1)
        x(iRip,:) = nan;
    end
    
end
% send the output out...
pre_rip_intervals = x;
