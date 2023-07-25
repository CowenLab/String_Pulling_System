function [Combos,CC,CCsh,xdim,stats, SIGNIF] = CrossCorrShuffle_AllCombos(TS, xcorr_window_msec, xcorr_bin_size_msec, start_end_uS)
%
if nargin < 4
    start_end_uS = [0 inf];
end
Combos=[];xdim=[];stats=[]; 
MIN_NUM_SPIKES = 20;
[Cell_1_idx, Cell_2_idx]  = find(triu(ones(length(TS))));
%%
CC = zeros(length(Cell_1_idx),xcorr_window_msec/xcorr_bin_size_msec + 1)*nan;
CCsh = zeros(length(Cell_1_idx),xcorr_window_msec/xcorr_bin_size_msec + 1)*nan;
SIGNIF = zeros(length(Cell_1_idx),2)*nan;
stats = cell(length(Cell_1_idx),1);
for iC = 1:length(Cell_1_idx)
    if length(TS{Cell_1_idx(iC)}) > MIN_NUM_SPIKES && length(TS{Cell_2_idx(iC)}) > MIN_NUM_SPIKES
        [CC(iC,:),CCsh(iC,:),xdim,stats{iC}] = CrossCorrShuffle(TS{Cell_1_idx(iC)}/100, TS{Cell_2_idx(iC)}/100, xcorr_window_msec, xcorr_bin_size_msec, start_end_uS/100,0);
        SIGNIF(iC,1) = stats{iC}.global_ttest;
        SIGNIF(iC,2) = stats{iC}.monosynaptic_is_above;
    end
end
Combos = [Cell_1_idx Cell_2_idx];

if nargout == 0
    for iC = 1:Rows(Combos)
        figure
        stairs(xdim-xcorr_bin_size_msec/2,CC(iC,:),'LineWidth',3)
        hold on
        stairs(xdim-xcorr_bin_size_msec/2,CCsh(iC,:),'LineWidth',3)
        xlabel('ms')
        axis tight
        pubify_figure_axis
        plot_vert_line_at_zero
        ylabel('count')
        title(sprintf('%d v %d mono %d glob p %1.3f',Combos(iC,1),Combos(iC,2),stats{iC}.monosynaptic_is_above,stats{iC}.global_stats(1)))
        
    end
end