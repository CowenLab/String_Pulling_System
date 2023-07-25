function  [P,TABLE,STATS] = anova_aligned_trial_intervals(trial_ca,intervals)
% function a = anova_aligned_trial_intervals(trial_ca,intervals)
% Given a cell array of trial alignment times (aligned on some event that
% repeats every trial - say the delivery of a stimulus), return the results
% of an ANOVA computed on the spikecounts found in the intervals
%
% trial_ca - cell array of alignemnt times {[-10 0 200 400] [-1000 9 200
% 4]}
% intervals - a nx2 matrix where each row is an interval (a start and stop
% time)
%
% OUTPUT: anova table.
% cowen
d = intervals(:,2) - intervals(:,1);
if diff(d) ~=0
    error('Intervals are not of the same length')
end
M = bin_ts_array(trial_ca,intervals);
[P,TABLE,STATS] = anova1(M',[],'off');
