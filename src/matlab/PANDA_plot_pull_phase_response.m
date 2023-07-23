function SPG_plot_pull_phase_response(phase_x,M_cell,title_str)
PLOT_LINES = false;
labs = {' Left' ' Right'};
for ii = 1:2
    M = Z_scores(M_cell{ii}')';

    subplot (2,2,ii)
    imagesc(phase_x,[],M)
    ylabel('Rat')
    title([title_str labs{ii}])
    pubify_figure_axis
    if ii == 2
        colorbar_label()
    end
    subplot (2,2,ii+2)
    plot_confidence_intervals(phase_x,M)
    if PLOT_LINES
        plot(phase_x,M)
    end
    plot_horiz_line_at_zero;
    xlabel('Phase (deg)')
    ylabel('Z scores')
    pubify_figure_axis

end
set(gcf,'Position',[ 253         133        1003         680])

