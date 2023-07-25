function SPEC_spike_field_coherence_track_pk_fq_plot(IN)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
p_th = 0.05;

for iN = 1:length(IN)
    if IN(iN).circ_p_to_shuff < p_th || IN(iN).freq_phase_p < p_th
        %             if true
        figure
        subplot(2,2,1)
        plot(IN(iN).pk_freq,IN(iN).pk_pow,'.')
        lsline
        ylabel('pow')
        xlabel('freq');
        axis tight
        title(sprintf('N%d, pts %1.3f ,  p %1.3f, z %1.3f',iN, IN(iN).circ_p_to_shuff ,IN(iN).circ_rtest_p, IN(iN).circ_rtest_z));
        subplot(2,2,2)
        polarhistogram(IN(iN).pk_phase,40)
        a = axis;
        hold on
        polarplot([IN(iN).preferred_phase IN(iN).preferred_phase ],[0 a(4)],'r','LineWidth',3)
        subplot(2,2,3)
        % Addresses Gia's question of whether there is a relationship
        % between phase and peak frequency.
        plot(IN(iN).pk_freq,IN(iN).pk_phase,'k.','MarkerSize',3)
        hold on
        plot(IN(iN).pk_freq,IN(iN).pk_phase + 2*pi,'k.','MarkerSize',3)
        
        ylabel('phase');xlabel('Hz')
        axis tight
        title(sprintf('circ_r %1.3f, circ p %1.3f',IN(iN).freq_phase_r ,IN(iN).freq_phase_p));
        
        subplot(2,2,4)
        histogram(IN(iN).pk_freq,30,'normalization','probability')
        xlabel('Hz')
        hold on
        plot_vert_line_at_zero(IN(iN).preferred_freq)
        %             plot_vert_line_at_zero(IN(iN).preferred_freq_median)
        ksdensity(IN(iN).pk_freq,IN(iN).psd_fqs)
    end
end


