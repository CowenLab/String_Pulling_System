function plot_PETH(M, x_axis, varargin) % A_msec, plot_type, sort_type)
% This is our current standard for PETH plotting.
% Cowen 2022.
if isempty(M)
    return
end
trial_spike_times = [];
raster_type = 'dots'; % 'tics'
summary_stat = 'mean_Hz';
smooth_bins = [];
smooth_mean_bins = [];
sort_type = [];
color_map = 1-gray;
trial_dur = [];
marker_size = 2;
xlabel_text = '';

Extract_varargin

if ~isempty(sort_type)
    [M,v] = sort_matrix(M,sort_type);
    % need to sort the rasters too!!!
    trial_spike_times = trial_spike_times(v(:,2));
end
% dt = median(diff(x_axis));
the_scale = 3;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
subplot(the_scale,1,1:(the_scale-1));
if ~isempty(smooth_bins)
    han = hanning(smooth_bins);
    M0 = conv_filter(M',han)'; % Careful - do not use this for computing the average - use the origianl M
else
    M0 = M;
end
if isempty(raster_type)
    imagesc(x_axis,[],M0);
    upper = min([ 3 max(M0(:))]);
    caxis([0 upper]);
    a = axis;
    c = colorbar_label;
    hold on
    if ~isempty(trial_dur)
        % plot the trial duration
        plot(trial_dur,[1:length(trial_dur)]','r+')
    end

    colormap(color_map);

    l = line([0 0],[0 Rows(M0)+.5]);
    set(l,'LineStyle',':')
    set(l,'LineWidth',1.5)
    set(l,'Color','r')
    set(gca,'XTickLabel','') % Good to keep this as you can then zoom in and still see the scale.
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(raster_type)
    % Align the spike times on the events.
    %     if isempty(A_msec)
    %         A_msec = Event_aligned_spike_times(spike_times_ts/10,sorted_alignments_ts/10,abs(range_msec(1)),range_msec(end)+dt );
    %     end
    for ii = 1:length(trial_spike_times)
        if ~isempty(trial_spike_times{ii})
            switch raster_type
                case 'dots'
                    plot(trial_spike_times{ii}, ones(1,length(trial_spike_times{ii}))*ii,'k.','MarkerSize',marker_size)
                case 'tics'
                    plot_raster(trial_spike_times{ii}',ii)
                otherwise
                    error('incorrect raster style')
            end

            hold on
        end

    end
    % make the plotting space for the rasters - otherwise it may cut
    % the edges.
    a(1:2) = x_axis([1 end]);
    a(3:4) = [.5 Rows(M)+.5];
    axis(a)
    axis ij
    if strcmpi(summary_stat,'trialsum')
        counts = sum(M,2);
        norm_counts = counts/max(counts);
        x = (norm_counts/3)*(a(3)-a(1))+a(1) ;
        plot(x, 1:length(counts),'-')
    end
end
a = axis;
l = line([0 0],a(3:4));
set(l,'LineStyle',':')
set(l,'Color','r')
set(l,'LineWidth',1.5)

ylabel('Trial');
pubify_figure_axis
set(gca,'XTickLabel',[])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Summarize.
% BUT WHAT ABOUT FIRING RATE- sum/bin size in sec.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(the_scale,1,the_scale)
binsize = median(diff(x_axis)); % assumes in sec.
% compute - Hz = n spikes over totoal time. Total time for a given
% bin is that bin times number of rows.
switch summary_stat
    case 'mean'
        if ~isempty(smooth_mean_bins)
            han = hanning(smooth_mean_bins);
            M2 = conv_filter(M',han/sum(han))';
        else
            M2 = M;
        end

        plot(x_axis, mean(M2),'k', 'LineWIdth',3);
        ylabel('mean spikes/bin')
    case 'trialsum'
        bar(x_axis, sum(M),'k'); % BAR - PREVIOUSLY USED barp is my own bar using the patch call. It rules. -dt/2
        ylabel('Count')
    case 'mean_Hz'
        if ~isempty(smooth_mean_bins)
            han = hanning(smooth_mean_bins);
            M1 = conv_filter(M',han/sum(han))';
        else
            M1 = M;
        end
        M2 = M1./binsize;
        plot_confidence_intervals(x_axis, M2);
        ylabel('mean Hz')
    otherwise
        error('wrong')
end

axis tight
xlabel(xlabel_text)
a = axis;
l = line([0 0],a(3:4));
set(l,'LineStyle',':')
set(l,'Color','r')
set(l,'LineWidth',1.5)
pubify_figure_axis
% subplot(the_scale,1,1:(the_scale-1));
% box off

