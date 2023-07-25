% Optimal_threshold_runner
% automatically goes to the currently active cheetah directory and
% generates a list of optimal thresholds for spike detection.
%
% cowen
d = find_active_cheetah_dir;
cd (d)
Canonical_comparison;
Optimal_thresholds;