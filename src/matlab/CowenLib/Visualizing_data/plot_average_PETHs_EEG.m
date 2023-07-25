function [M x_axis] = plot_average_PETHs_EEG(T_EEG, align_events_ca, sFreq, sec_before, sec_after, markers,  color_ca, params)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
%   Continuous data = a matrix of timestamps and data (2 col)
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
if nargin < 8
    params = {'rectify'};
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
for ii =1:length(align_events_ca)
 %   if isempty(align_events_ca{ii})
 %       M{ii} = [];
    [M{ii},x_axis] = PETH_EEG(T_EEG,sFreq,align_events_ca{ii},sec_before,sec_after,params); % rectify
    if ~isempty(M{ii})
        [mn_Mp{ii}, ci_Mp{ii}] = normci(M{ii});
        %
        %x_axis = x_axis/1000;
        plot_confidence_intervals(x_axis, mn_Mp{ii},ci_Mp{ii},color_ca{ii});
        hold on
    end
end
axis tight
box off
if ~isempty(markers)
    plot_markers(markers,3)
end