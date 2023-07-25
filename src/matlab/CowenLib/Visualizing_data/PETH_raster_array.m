function [M, x_axis, A_msec, p ] = PETH_raster_array(spike_times_uS_array,alignments_uS,bin_and_inc_size_msec,time_before_msec,time_after_msec,option)
% function [M, x_axis, A_msec ] = PETH_raster_array(spike_times_uS_array,alignments_uS,bin_and_inc_size_msec,time_before_msec,time_after_msec,option)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% INPUT:
%  spike_times_uS_array   - array of uS timestamps.
%  alignments_Us    - uS
%  bin_and_inc_size_msec - the bin size in the spike time matrix.
%  time_before_msec - time before the alignment
%  time_after_msec  - time after the alignment.
%
% OUTPUT:
%  M - a matrix with the spikes aligned
%  A - a cell array of spike times that are aligned with time 0 at the event time.
%  x_axis - the x axis of the plot
%
% % Cowen - just a wrapper for PETH Raster. 2020

if nargin < 6
    option = 0;
end
if isempty(alignments_uS) || length(alignments_uS) == 1
    disp('No alignments or only one alignment specified.')
    M = []; A_msec=[]; x_axis=[];
    return
end
if ~isa(spike_times_uS_array,'cell')
    spike_times_uS_array = {spike_times_uS_array};
end

M = cell(length(spike_times_uS_array),1);
p = zeros(length(spike_times_uS_array),1);

for iN = 1:length(spike_times_uS_array)
    if length(spike_times_uS_array{iN}) > 20
        % Need to convert to 1/10 msec due to legacy silliness.
        [M{iN}, x_axis, A_msec ] = PETH_raster(spike_times_uS_array{iN}/100,alignments_uS/100,bin_and_inc_size_msec,time_before_msec,time_after_msec,option);
        BEFIX = x_axis<0;
        AFTIX = x_axis>0;
        p(iN) = signrank(mean(M{iN}(:,BEFIX),2)-mean(M{iN}(:,AFTIX),2));
    end
end

