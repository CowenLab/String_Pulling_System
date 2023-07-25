function [f] = Check_cluster_from_file(t_file, waveform_file, varargin)
% INPUT: t_file = the name of the tfile. If the name is partial(i.e. TT4) then
%                 check cluster from file will do a search for all files with that
%                 prefix.
%
%
%        tt_file = the name of the tt file
%
%        varargins: These optional additional parameters allow additional plots to be 
%                   added to the check cluster plot. The format for these plots
%                   is 'parameter name' (in single quote), parameter values.
%        To plot place field and scatter field plots:
%
% f = Check_cluster_from_file('TT10','C:\Data\Stress\6989_05\TT10.dat',...
%      'position','C:\Data\Stress\6989_05\VT1.ascii',...
%      [28261548, 41298161;63768362, 78104458],'save_figures','jpeg')
%         
%        the first arguement after 'position' is the name of the ascii position file
%        the second is a matrix of start and end times for the epoch.
% 
%
%        to save files instead of keeping up a figure window, pass in 
%          'save_figures' as parameter 1 and 'eps' or 'fig' or 'bmp' as parameter 2.
%          parameter 2 specifies the file format (see saveas for other options).
%
% OUTPUT: the file handles of the figures and a plot of cluster information
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen, modified from ADR CheckCluster
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VARIABLE DECLARATIONS:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
draw_position = 0;
draw_PETH = 0;
save_figures = 0;
text_font_size = 7;
figure_count = 1;
n_place_bins = 14; % Default for place fields.
f = [];
fig_name = [];
file_type = 'TT'; % default.
nmsgs = 1;

msgstr = {fig_name};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find all files that correspond the the passed in TT file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get rid of the extension if there is any. We'll put it back later.
[tfile_path, name, ext] = fileparts(t_file);
[ttfile_path, tt_name, tt_ext] = fileparts(waveform_file);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract the varargins if there are any-- and draw stuff.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
iV = 1;
while iV <= length(varargin)
    
    if size(varargin{iV},2) == 1
        varargin{iV} = varargin{iV}';
    end
    switch varargin{iV}
    case 'file_type'
        iV = iV + 1;
        file_type = varargin{iV};
        iV = iV + 1;
        
    case 'position'
        iV = iV + 1;
        draw_position = 1;
        disp('Loading Position File.')     
        n_place_bins = 14;
        position = load(varargin{iV}); 
        iV = iV + 1;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Try a 'smart' way of determining if this is 
        %     Cheetah NT or sun position info:
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if position(1,1) > 200000
            time_divisor = 1;
        else
            time_divisor = 1;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Having a position of 0,0 is typically an error in tracking so get rid of it.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        position = position(find(position(:,2)~=0),:);
        position = position(find(position(:,3)~=0),:);
        epoch_times = varargin{iV};
        iV = iV + 1;
        n_epochs = size(epoch_times,1);
        for epoch = 1:n_epochs
            x_pos{epoch} = Restrict(tsd(floor(position(:,1)/time_divisor),position(:,2)),epoch_times(epoch,1),epoch_times(epoch,2));
            y_pos{epoch} = Restrict(tsd(floor(position(:,1)/time_divisor),position(:,3)),epoch_times(epoch,1),epoch_times(epoch,2));
            %x_pos{epoch} = Smooth_tsd(x_pos{epoch},30);
            %y_pos{epoch} = Smooth_tsd(y_pos{epoch},30);
        end
    case 'n_place_bins'
        iV = iV + 1;
        n_place_bins = varagin{iV};
        iV = iV + 1;
        
    case 'PETH'
        iV = iV + 1;
        draw_peth = 1;
    case 'save_figures'
        iV = iV + 1;
        save_figures = 1;
        fig_string = varargin{iV};
        iV = iV + 1;
    case 'fig_name'
        iV = iV + 1;
        fig_name = varargin{iV};
    otherwise
        error('Unknown Parameter')
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(t_file)
    eval(['st = Nlx2Mat' file_type '(''' waveform_file ''',1,0,0,0,0,0);']);
    spike_times = ts(st);
    [p,n,e] = fileparts(waveform_file);
    fig_name = n;
else
    [p,n,e] = fileparts(t_file);
    fig_name = n;
    if strcmpi(e,'.tstxt')
        spike_times = load(t_file);
    else
if iscell(t_file)
        spike_times = LoadSpikes(t_file);
else
        spike_times = LoadSpikes({t_file});
end
        spike_times = spike_times{1};
    end
end

eval(['[ t, wv] = Nlx2Mat' file_type '(''' waveform_file ''',1,0,0,0,1,0);']);

%[t, wv] = LoadTT0_nt(waveform_file,Data(spike_times),1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If no spikes, go to the next file.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(t)
    t = floor(t);
    u = setdiff(floor(Data(spike_times)),t);
    if ~isempty(u)
        disp(['WARNING: ' num2str(length(u)) ' spikes in the t file do not correspond to spikes in the tt file.'])
    end
    
    [peak, ipeak] = max(wv, [], 1);
    [vlly, ivlly] = min(wv, [], 1);
    
    
%    [junk, tfile_name] = fileparts(current_t_file_name);
%    [junk, ttfile_name] = fileparts(waveform_file);
    
    f(figure_count) = figure('Name', fig_name, 'NumberTitle', 'Off');
    figure_count = figure_count + 1;
    
    clf
    colormap(1-gray);
    nPlot = 4;
    mPlot = 2;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PLOT: AvgWaveform
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    CO = get(gca,'ColorOrder');
    switch file_type
    case 'TT'
        subplot(nPlot,mPlot,1);
        for it = 1:4
            mWV = mean(squeeze(wv(:,it,:)),2);
            sWV = std(squeeze(wv(:,it,:))');;
            xrange = (34 * (it-1)) + (1:32); 
            hold on;
            h = plot(xrange, mWV);
            set(h, 'Color',CO(it,:))
            h=errorbar(xrange,mWV,sWV); 
            set(h, 'Color',CO(it,:))
        end
        sw = ivlly - ipeak;
        mSW = mean(sw,1);
        vSW = std(sw, 1);
        
        
    if 1    
        msgstr{nmsgs}   = sprintf('spikewidth (Ch1,2) = %4.2f +/- %4.2f   %4.2f +/- %4.2f', ...
            mSW(1), vSW(1), mSW(2), vSW(2));
        msgstr{nmsgs+1} = sprintf('spikewidth (Ch3,4) = %4.2f +/- %4.2f   %4.2f +/- %4.2f', ...
            mSW(3), vSW(3), mSW(4), vSW(4));
        nmsgs = nmsgs+2;
        
        p2v = abs(peak)./abs(vlly);
        mp2v = mean(p2v,1);
        vp2v = std(p2v,1);
        
        
        msgstr{nmsgs}   = sprintf('peak/valley (Ch1,2) = %4.2f +/- %4.2f    %4.2f +/- %4.2f', ...
            mp2v(1), vp2v(1), mp2v(2), vp2v(2));
        msgstr{nmsgs+1} = sprintf('peak/valley (Ch3,4) = %4.2f +/- %4.2f    %4.2f +/- %4.2f', ...
            mp2v(3), vp2v(3), mp2v(4), vp2v(4));
        
        
        nmsgs = nmsgs+2;
    end
    case 'SE'
        subplot(nPlot,mPlot,1:2);
        
        wv = squeeze(wv);
        mWV = mean(wv')';
        sWV = std(wv')';
        hold on;
        h = plot(mWV);
        set(h, 'Color','b')
        h=errorbar(xrange,mWV,sWV); 
        set(h, 'Color','r')
        
        
    otherwise
        error('what?')
    end
    
    axis off
    axis([0 140 -2100 2100])
    set(gca,'FontSize',text_font_size)
    title('Average Waveform');
    
    hold off
    drawnow
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PLOT: ISIStats (text)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    subplot(nPlot, mPlot, 2);
    
    
    
    nmsgs = nmsgs+1;
    if isempty(getenv('USER'))
        msgstr{nmsgs} = sprintf('Cut on %s', date);
    else   
        msgstr{nmsgs} = sprintf('Cut by %s on %s', getenv('USER'), date);
    end
    nmsgs = nmsgs+1;
    nSpikes = length(t);
    msgstr{nmsgs} = sprintf('%d spikes ', nSpikes);
    nmsgs = nmsgs+1;
    mISI = mean(diff(t));
    fr = 10000 * nSpikes/(t(end) - t(1));
    
    
    msgstr{nmsgs} = sprintf('firing rate = %.4f spikes/sec ', fr);
    
    
    nmsgs = nmsgs+1;
    

    h=text(0,0.5, msgstr);
    set(h,'FontSize',text_font_size)
    axis off
    drawnow
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PLOT: HistISI
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    subplot(nPlot, mPlot, 3);
    HistISI(ts(t));
    set(gca,'FontSize',text_font_size)
    title('histogram of log(ISI)','FontSize',text_font_size)
    ylabel('nSpikes','FontSize',text_font_size);
    xlabel('msec','FontSize',text_font_size)
    axis tight
    drawnow
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Peak plot
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    subplot(nPlot, mPlot, 4);
    plot(peak(:,2),peak(:,1),'.')
    hold on
    plot(peak(:,2),-peak(:,3),'.')
    plot(-peak(:,4),-peak(:,3),'.')
    plot(-peak(:,4),peak(:,1),'.')
    plot(0,0,'+r')
    H = findobj(gca, 'Type', 'Line');
    set(H, 'MarkerSize', 2)
    axis tight
    axis off
    title(['Peak Plot'],'FontSize',text_font_size)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PLOT: AutoCorr (AutoCorr.m is VERY slow and peter's autocorr.dll C program does not work yet)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    subplot(nPlot, mPlot, 5);
    acorr_bin_msec = 4;
    [histvals,x] = autocorr(t, acorr_bin_msec, 250); % This is peter's C autocorr
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %acorr(floor(length(acorr)/2+1)) = 0;    % set 0 lag to 0 for scaling
    % Cannot use bar-- there is some matlab bug that prevents it's use in this subplot.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    plot(x,histvals);			% show acorr
    
    xlabel(['msec (' num2str(acorr_bin_msec) 'msec binsize)'],'FontSize',text_font_size)
    ylabel('rate','FontSize',text_font_size)
    h = title('Autocorrelation','FontSize',text_font_size);
    drawnow
    set(gca,'FontSize',text_font_size)
    % PLOT: AutoCorr (AutoCorr.m is VERY slow and peter's autocorr.dll C program does not work yet)
    subplot(nPlot, mPlot, 6);
    d = diff(t)/10; % Convert isi to msec.
    H = plot(d(1:end-1),d(2:end),'.');
    set(H, 'MarkerSize', 1)
    set(gca, 'XScale', 'log');
    set(gca, 'YScale', 'log');
    axis([0 1500 0 1500])
    xlabel('msec (t)','FontSize',text_font_size)
    ylabel('msec (t+1)','FontSize',text_font_size)
    set(gca,'FontSize',text_font_size)
    
    if 0
        acorr_bin_msec = 1;
        [histvals,x] = autocorr(t, acorr_bin_msec, 50); % This is peter's C autocorr
        
        %acorr(floor(length(acorr)/2+1)) = 0;    % set 0 lag to 0 for scaling
        % Cannot use bar-- there is some matlab bug that prevents it's use in this subplot.
        
        bar(x,histvals);			% show acorr
        
        xlabel(['msec (' num2str(acorr_bin_msec) 'msec binsize)'],'FontSize',text_font_size)
        ylabel('rate','FontSize',text_font_size)
        h = title('Autocorrelation','FontSize',text_font_size);
        drawnow
        set(gca,'FontSize',text_font_size)
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Time plot
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    subplot(nPlot, mPlot, 7:8);
    
    plot(t/10000/60,peak(:,1),'.')
    
    set(gca,'FontSize',text_font_size)
    xlabel('Time (minutes)','FontSize',text_font_size)
    ylabel('Peak','FontSize',text_font_size)
    
    H = findobj(gca, 'Type', 'Line');
    
    set(H, 'MarkerSize', 2)
    axis tight
    
    drawnow
    if save_figures
        saveas(f(figure_count-1),[fig_name fig_name '_ClustView.' fig_string ],fig_string);
        close(f(figure_count-1))
    end
    
    if draw_position
        f(figure_count) = figure('Name', ['Place Fields ' fig_name], 'NumberTitle', 'Off');
        figure_count = figure_count + 1;
        subplot_count = 1;
        for epoch = 1:n_epochs
            subplot(n_epochs*2,2,subplot_count)
            subplot_count = subplot_count + 1;
            spikes = Restrict(spike_times,epoch_times(epoch,1), epoch_times(epoch,2));
            [TC,Occ] = TuningCurves({spikes}, x_pos{epoch}, n_place_bins, y_pos{epoch}, n_place_bins);
            NTC = TC./Occ;
            fq = length(Data(spikes))/((epoch_times(epoch,2)- epoch_times(epoch,1))/10000);
            imagesc(NTC');h = colorbar;colormap(1-gray)
            set(h,'FontSize',text_font_size)
            title([ fig_name ' PF Period: ' num2str(epoch) ' Rate: ' num2str(fq) 'Hz'],'FontSize',text_font_size)
            axis ij
            axis off
            subplot(n_epochs*2,2,subplot_count)
            subplot_count = subplot_count + 1;
            [SFx, SFy] = ScatterFields({spikes}, x_pos{epoch},y_pos{epoch});
            x = Data(x_pos{epoch});
            y = Data(y_pos{epoch});
            plot(x(1:10:end),y(1:10:end),'c.')
            title([ fig_name ' ScatterFields Period: ' num2str(epoch)],'FontSize',text_font_size)
            axis ij
            axis tight
            axis off
            hold on
            plot(Data(SFx),Data(SFy),'rx')
            drawnow
            
            subplot(n_epochs*2,2,subplot_count:subplot_count+1)
            subplot_count = subplot_count + 2;
            r = Range(x_pos{epoch},'sec');
            plot(r(1:10:end),x(1:10:end)+y(1:10:end),'c')
            hold on
            %plot(r(1:10:end),y(1:10:end),'g.')
            plot(Range(SFx,'sec'),Data(SFx)+Data(SFy),'rx')
            %            plot(Range(SFy,'sec'),Data(SFy),'kx')
            xlabel('sec','FontSize',text_font_size)
            ylabel('position (x + y)','FontSize',text_font_size)
            title([ fig_name ' Position Vs. Time Period: ' num2str(epoch) ' Rate: ' num2str(fq) 'Hz'],'FontSize',text_font_size)
            %title('Position over time','FontSize',text_font_size)
            axis tight
            set(gca,'FontSize',text_font_size)
        end
        if save_figures
            saveas(f(figure_count-1),[fig_name fig_name '_PF.' fig_string],fig_string);
            close(f(figure_count-1))
        end
        
    end % draw position
    clear t, wv;
    pack
end % if isempty

