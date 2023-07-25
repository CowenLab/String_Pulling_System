function [M, A_msec, x_axis] = Align_spike_times(spike_times_ts,alignments_ts,bin_and_inc_size_msec,time_before_msec,time_after_msec,option)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create a PETH with a raster or aligned rate map of trials above it.
%   renamed to PETH_raster.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[M, A_msec, x_axis] = PETH_raster(spike_times_ts,alignments_ts,bin_and_inc_size_msec,time_before_msec,time_after_msec,option)

