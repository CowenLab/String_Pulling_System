function [M x_axis Morig] = plot_average_PETHs(spike_times_ts, align_events_ca, sec_before, sec_after, markers,  color_ca)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
%   spike_times_ts = either a vector of spike times or a filename for the
%     position data or the eeg data.
%   align_events_ca = a cell array of alignment events align_events_ca{1:4}
%    - If a cell array of 4 then 1 and 2 are assumed to be predictive and 3
%    and 4 are assumed to be non-predictive.
%   event_names_ca = same size but with the names of the aligned events.
%   sec_before/after = the seconds before/after the alighment event to
%   display
%   markers = locations to place vertical markers on the plot
%   title_string = title of the plot
%   color_ca = cell array of colors for each line (same size as
%   align_events_ca)
%
% cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 6
    color_ca = {'b' 'r' 'k' 'g' 'm' 'c'};
end
if nargin < 5
    markers = [];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Other parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
convpts = 20;
binsize_msec = 2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii =1:length(align_events_ca)
    [Morig{ii}, x_axis, A_msec{ii}] = PETH_raster(spike_times_ts, align_events_ca{ii}/100, binsize_msec, sec_before*1000, sec_after*1000);
    M{ii}      = conv_filter(Morig{ii}',hanning(convpts)/sum(hanning(convpts)))';
    M{ii}      = M{ii}  * 1000/binsize_msec; % Ummm, convert to rate?
    %[mn_Mp{ii}, ci_Mp{ii}] = expfit(M{ii});
    if ~isempty(M{ii})
        [mn_Mp{ii}, ci_Mp{ii}] = normci(M{ii});
        %
        x_axis = x_axis/1000;
        plot_confidence_intervals(x_axis, mn_Mp{ii},ci_Mp{ii},color_ca{ii});
        hold on
    end
end
axis tight
box off
if ~isempty(markers)
    plot_markers(markers,3)
end