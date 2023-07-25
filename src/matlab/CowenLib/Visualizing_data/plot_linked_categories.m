function plot_linked_categories(D,groups_to_compare, group_labels, variables_to_color_ca, colors)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function plot_linked_categories(D,groups_to_compare, group_labels, variables_to_color_ca, colors)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is also called the parallel coordinates display. See Exploratory
% Analysis of Spatial and Temporal Data
%
% INPUT: D a n group x n variable matrix of points. for instance, each
% column could be a neuron. The first row could be firing_rate, the second
% could be stimulus_sensitivity. 
% groups_to_compare woudl be the paired comparisons in the order they 
%  should apprear. e.g. compare 1 vs 2 and 3 vs 4.s would then indicate which categories to compare. For instance
% could then be 1 (for firing rate) and 2 for selctivity.
%
% group_labels - a cell array of text data that describe each group.
%
% variables_to_color_ca = collections of columns in D to identify with
% unique colors or linetypes.
%
% colors - linetype/color information.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen (2006)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nVbls = Cols(D);
nComparisons = Rows(groups_to_compare);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Normalize each row of D to go between it's minimum and maximum.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
D = standardize_range(D')'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Put outer loop for groups here.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ycount = 1
for iC = 1:nComparisons
    plot([D(groups_to_compare(iC,1),:);  D(groups_to_compare(iC,2),:)],[ ones(1,nVbls)*ycount; ones(1,nVbls)*(ycount+1) ],'bo-')
    hold on
    ycount = ycount + 2;
end
box off
set(gca,'YTick',1:(nComparisons+1))
set(gca,'YTickLabel',group_labels)
set(gca,'XTickLabel',[])