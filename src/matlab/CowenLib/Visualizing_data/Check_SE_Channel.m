function Check_SE_Channel(waveform_file, timestamp_file, varargin)
% Creates a graphic summary sheet of the data on a particular channel or cell.
%
% INPUT 
%  file to check and 
%  optionally the start and end time to restrict the check to
%  a limit-- if exceeded, then subsample the data.
%
%  If the tfile field is an empty matrix, then the check is done
%   on all of the spikes in the waveform data file.
%  
%  Providing features also generates feature projections:
%  Providing event times also produces PETHs around the times:
%  The 'saveit' option saves the image as a .png file.
%   A long and painful call to Check_SE_Channel which utilizes these options is as follows...
%
%   Check_SE_Channel('nsSE_F5.dat', 'nsSE_F5_1.t','event_times',EVT.Stim,'before_ts',1000*1000,'after_ts',1000*1000,'binsize_ts',20*1000,'features_to_show',{'energy', 'peak','SpikeWidth','stdPC1','stdPC2','waveFFT'},'saveit',1)
%    or if you want the info from an entire channel.
%   Check_SE_Channel('nsSE_F5.dat', [],'event_times',EVT.Stim,'before_ts',1000*1000,'after_ts',1000*1000,'binsize_ts',20*1000,'features_to_show',{'energy', 'peak','SpikeWidth','stdPC1','stdPC2','waveFFT'})
%
% OUTPUT
%   a summary sheet
% 
% TO DO: Make it general so the user can specify the file type. (SE TT ST)
% cowen 2002
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
if nargin == 1
    timestamp_file = [];
end
start_and_end_time = [];
event_times = [];
subsample_limit = 120000;
text_font_size  = 8;
before_us  = 500 * 1000;
after_us   = 500 * 1000;
binsize_us = 20 * 1000;
features_to_show = [];
saveit = 0;
ncols = 3;
title_string = [];
extract_varargin;
if ~isempty(event_times)
    nrows = 4;
else
    nrows = 3;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
% Load the data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
if isempty(timestamp_file)
    fig_file_name = waveform_file;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    % only a waveform file is specified.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    [p,n,e] = fileparts(waveform_file);
    title_string = n;
    %error('1')
    if ~isempty(start_and_end_time)
        try
            [t_us wv header] = Nlx2MatSE(waveform_file,1,0,0,0,1,1, start_and_end_time(1),start_and_end_time(2));
        catch
            error([n e ' failed']);
        end
        total_spikes = length(t_us);
        
    else
        try
            [t_us header] = Nlx2MatSE(waveform_file,1,0,0,0,0,1);
        catch
            error([n e ' failed']);
        end
        total_spikes = length(t_us);
        if total_spikes>subsample_limit
            disp(['File has ' num2str(length(t_us)) ' records, subsampling (random).'])
            t_us = t_us(unique(ceil(rand(1,30000)*length(t_us))));
            [t_us wv] = Nlx2MatSE(waveform_file,1,0,0,0,1,0,t_us);
            title_string = [title_string ' SubSampled '];
        else
            [t_us wv] = Nlx2MatSE(waveform_file,1,0,0,0,1,0);
        end    
    end
    
else
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    % a timestamp and waveform file is specified.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    fig_file_name = timestamp_file;
    [p,n,e] = fileparts(fig_file_name);
    title_string = n;
    
    % Load in the timestamp file.
    switch e
    case '.t'
        file_type = 't';
        tfp = fopen(timestamp_file, 'rb','b'); % Open the file big-endian. I don't know why-- PCs are little endian but this is what works. Otherwise you are a factor off.
        if (tfp == -1)
            warning([ 'Could not open tfile ' timestamp_file]);
            return
        end
        ReadHeader(tfp);    
        t_to_get = fread(tfp,inf,'uint32');	%read as 32 bit ints        fclose(tfp);
        nspikes = length(t_to_get);
        if isempty(t_to_get)
            error('No timestamps found')
        end
        
        if ~isempty(start_and_end_time)
            idx = find(t_to_get > start_and_end_time(1) & t_to_get <= start_and_end_time(2) );
            t_to_get = t_to_get(idx);
        end
        % Subsample if necessary
        if length(t_to_get)>subsample_limit
            disp(['File has ' num2str(length(t_to_get)) ' records, subsampling (random).'])
            t_to_get = t_to_get(unique(ceil(rand(1,30000)*length(t_to_get))));
            title_string = [title_string ' SubSampled ' num2str(length(t_to_get)) '/' num2str(nspikes)];
        end
        
        [p,n,e] = fileparts(waveform_file);
        t_in_file = Nlx2MatSE(waveform_file,1,0,0,0,0,0);
        if isempty(t_in_file)
            error('Nothing in SE file')
        end
        
        [t_us idx] = intersect(floor(t_in_file/100), t_to_get);
        if isempty(idx)
            error('Timestamps are not found in waveform data file.')
        end
        
        disp(['Found ' num2str(length(t_us)) ' of the ' num2str(length(t_to_get)) ' records in the waveform file. Loading.'])
        [t_us wv header] = Nlx2MatSE(waveform_file,1,0,0,0,1,1, unique(t_in_file(idx)));
        
        
    case '.nts'
        file_type = 'nts';
        
        if findstr(timestamp_file, '*') > 0
            f = find_files(timestamp_file);
            tmpt = [];
            disp(['Found ' num2str(length(f)) ' files'])
            
            for ii = 1:length(f)
               [tmpt] = nlx2matTS(f{ii},1,0);
               t_to_get = [t_to_get tmpt];
               t_to_get = unique(t_to_get);
            end
        else
            [t_to_get] = nlx2matTS(timestamp_file,1,0);
            ntsfp = fopen(timestamp_file,'r');
            h = fread(ntsfp, 16384,'char');
            while(~feof(ntsfp))
                t_to_get = fread(ntsfp, 1,'unsigned long');
            end
            fclose(ntsfp);
            
        end
        if isempty(t_to_get)
            error('No timestamps found')
        end

        if min(t_to_get)<0
            error('Negative timestamps found')
        end
        
        [t_us wv header] = Nlx2MatSE(waveform_file,1,0,0,0,1,1, t_to_get);
        header = [];
    case '.tstxt'
        t_to_get = load(timestamp_file);
        t_to_get(end) = []; %The last one may be incomplete.
        disp(['Found ' num2str(length(t_to_get)) ' timestamps in ts file.']);
        [t_us wv header] = Nlx2MatSE(waveform_file,1,0,0,0,1,1, t_to_get);
    otherwise
        error('Unknown timestamp file format.')
    end
    % If nlx can't find a record, it returns 0 timestamps. Get rid of them.
    wv = wv(:,:,find(t_us>0));
    t_us = t_us(find(t_us>0));
    total_spikes = length(t_us);
    disp(['Found ' num2str(total_spikes) ' timestamps that matched in data file.']);
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now that the data is loaded, use the header information to convert the 
% values to microvolts instead of bit values.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(header) 
    a = sscanf(header{15}, '%s %f');
    if ~ischar(a)
        ADVolts = a(end);
        wv = wv*ADVolts*1e6;
        ylab = 'uV';
    else 
        ylab = 'pts (uV unknown)';
    end
else
    ylab = 'pts';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
t_us = t_us(:); % Make sure the timestamps are a vertical col -- ts is not very smart.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
wv = squeeze(wv)';
mn = mean(wv);
sd = std(wv);

validx = find(mn == min(mn));
validx = validx(1);

nplots = 4;
figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Waveform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%the_range = 1:32/sc_rate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Density plot. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot(nrows,ncols,[1 4])
normal_hist = 0;
[r,c] = size(wv);
if normal_hist
    [idx] = find(wv);
    H = ndhist([c'; wv(idx)'],[32 1000]',[1 -2048 ]',[32 2048]')';
    s = sum(H');
    H(find(s==0),:) = [];
    imagesc(H);
    caxis([0 min([max(H(:)) maxc])])
    %colormap(1-gray)
    axis off
    axis xy
else 
    % Waveform Density Plot.
    limit = 4000; % max number of points to bin at one time (to help with memory issues)
    interpolate = 1;
    if r > 20000
        rnds = randperm(r);
        Waveform_density(wv(rnds(1:10000),:),interpolate,limit,0);
    else
        Waveform_density(wv,interpolate,limit,1);
    end
end
hold on 
plot(1:32,mn,'k-.','LineWidth',2)
plot(1:32,mn+sd,'k:','LineWidth',2)
plot(1:32,mn-sd,'k:','LineWidth',2)
ylabel(ylab,'FontSize',text_font_size);

if 0
    subplot(nrows,ncols,[1 ])
    plot(1:32,mn)
    hold on 
    plot(1:32,mn+sd,'r')
    ylabel(ylab,'FontSize',text_font_size);
end
%[p, n, e] = fileparts( fig_file_name);
title( title_string )
axis tight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ISI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(nrows,ncols,2)
ISI_histogram(t_us/100); % New cheetah timestamps are in micorseconds. 
% Convert to .1msec old format for HistISI.
ylabel('nSpikes','FontSize',text_font_size);
xlabel('msec','FontSize',text_font_size);
axis tight
box off
n_out = length(find(diff(t_us)<2*1000)); % Find n spikes with ISI < 2 msec.
title ([num2str(length(t_us)) ' of ' num2str(total_spikes) ' spikes displayed, ' num2str(100*n_out/length(t_us)) '% < 2ms ISI'],'FontSize',text_font_size)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Autocorrelation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(nrows,ncols,3)

acorr_bin_msec = 4;
[histvals,x] = autocorr(t_us/100, acorr_bin_msec, 250); % This is peter's C autocorr

plot(x,histvals);			% show acorr

xlabel(['msec (' num2str(acorr_bin_msec) 'msec binsize)'],'FontSize',text_font_size)
ylabel('rate (Hz)','FontSize',text_font_size)
title(['ACorr, Mean Rate= ' num2str(total_spikes/((t_us(end) - t_us(1))/1e6) ) ' Hz'],'FontSize',text_font_size)
box off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% wv(time) x wv(time+1) plot (how the waveform changes)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(nrows,ncols,5)
r = randperm(length(t_us));
%
npts = [min([300, length(t_us)])];
plot(wv(r(1:npts),:)')
title(['Subsample (' num2str(npts) 'pts)'],'FontSize',text_font_size)
axis tight
box off

if 0
    subplot(nrows,ncols,5)
    % Waveform Density Plot.
    limit = 4000; % max number of points to bin at one time (to help with memory issues)
    interpolate = 1;
    if r > 20000
        rnds = randperm(r);
        Waveform_density([wv(1:10000,2:end) - wv(1:10000,1:end-1)],interpolate,limit,1);
        
        title('subsampled','FontSize',text_font_size)
    else
        Waveform_density([wv(:,2:end) - wv(:,1:end-1)],interpolate,limit,1);
        
    end
    title('1st drv','FontSize',text_font_size)
    ylabel(ylab,'FontSize',text_font_size);
    
    if 0
        h = Waveform_time_dynamics_plot(wv);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Time and time + 1 plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(nrows,ncols,6)
d = diff(t_us/1000); % Convert to msec
if 0
    H = plot(d(1:end-1),d(2:end),'.');
    set(H, 'MarkerSize', 2)
    set(gca, 'XScale', 'log');
    set(gca, 'YScale', 'log');
    %axis([0 1500 0 1500])
    xlabel('(t ms)','FontSize',text_font_size)
    ylabel('(t+1 ms)','FontSize',text_font_size)
    set(gca,'FontSize',text_font_size)
end
if 1
    d = log(d);
    d = d(:);
    xlim = 200;
    ylim = 200;
    H = ndhist([d(1:end-1)'; d(2:end)'],[xlim ylim]',[min(d) min(d)]',[max(d) max(d)]')';
    H = log(H);
    mn = min(H(find(H>-100)));
    H(find(H < -100)) = mn;
    imagesc(Hsmooth(H));          
    %imagesc(H);          
    axis xy
    axis off
else
    H = plot(d(1:end-1),d(2:end),'.');
    set(H, 'MarkerSize', 2)
    set(gca, 'XScale', 'log');
    set(gca, 'YScale', 'log');
    axis([0 1500 0 1500])
    xlabel('msec (t)','FontSize',text_font_size)
    ylabel('msec (t+1)','FontSize',text_font_size)
    set(gca,'FontSize',text_font_size)
    axis square
end

%H = ndhist(log([d(1:end-1); d(2:end)]),[80;80],[0;0],[10;10])';
%imagesc(H)
%contour(H)
%xlabel('(log t ms)','FontSize',text_font_size)
%ylabel('(log t+1 ms)','FontSize',text_font_size)

axis xy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Time and peak and valley.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(nrows,ncols,7:9)
plot(t_us,wv(:,8),'b.','MarkerSize',1)
hold on
plot(t_us,wv(:,validx),'m.','MarkerSize',1)
axis tight
xlabel('time','FontSize',text_font_size)
ylabel('Peak and Valley','FontSize',text_font_size)

%xlabel('amp(t)')
%ylabel('amp(t+1)')
if ~isempty(event_times)
    
    subplot(nrows,ncols,10:12)
    
    if ~isempty(event_times)
        PETH(t_us,event_times,[before_us after_us],binsize_us);
    end
    box off
end
if saveit
    [p,n,e] = fileparts(fig_file_name);
    saveas(gcf,[n '_WVInfo'],'png')
    close
end
orient tall

% --------------------------------------------------------
% Show the density plots of the feature space.
% --------------------------------------------------------

if ~isempty(features_to_show)
    % --------------------------------------------------------
    % Generate each feature.
    % --------------------------------------------------------
    figure
    
    nFeatures = length(features_to_show);
    a_dim = ceil(ceil((nFeatures^2-nFeatures)/2)/3);
    b_dim = 3;
    count = 1;
    for iF = 1:length(features_to_show)
        for jF = (iF+1):length(features_to_show)
            [FeatureData1, FeatureNames1] = ...
                feval(['feature_', features_to_show{iF}], tsd(t_us,reshape(wv,size(wv,1),1,size(wv,2))), [1 0 0 0]);
            [FeatureData2, FeatureNames2] = ...
                feval(['feature_', features_to_show{jF}], tsd(t_us,reshape(wv,size(wv,1),1,size(wv,2))), [1 0 0 0]);
            
            subplot(a_dim,b_dim ,count)
            % Check to see if you have some integer data-- if so, ad some random noise to make it viewable.
            is_int = (sum(round(FeatureData2(:))-FeatureData2(:)))== 0;
            
            if is_int
                FeatureData2 = FeatureData2 + rand(size(FeatureData2)) - .5;
            end
            is_int = (sum(round(FeatureData1(:))-FeatureData1(:)))== 0;
            
            if is_int
                FeatureData1 = FeatureData1 + rand(size(FeatureData1)) - .5;
            end
            
            %H = ndhist([c'; wvi(idx)'],[xlim ylim]',[1 mnwv ]',[xlim mxwv]')';
            if (1)
                xlim = 100;
                ylim = 100;
                H = ndhist([FeatureData1(:)'; FeatureData2(:)'],[xlim ylim]',[min(FeatureData1) min(FeatureData2)]',[max(FeatureData1) max(FeatureData2)]')';
                H = log(H);
                mn = min(H(find(H>-100)));
                H(find(H < -100)) = mn;
                imagesc(Hsmooth(H));          
                axis xy
                axis off
                
                
            else
                plot(FeatureData1,FeatureData2,'.','Markersize',1)
            end
            
            if count == 1
                [p, n, e] = fileparts( fig_file_name);
                title([[n e] ' ' FeatureNames1{1} ' Vs ' FeatureNames2{1}],'FontSize',text_font_size)
            else
                title([FeatureNames1{1} ' Vs ' FeatureNames2{1}],'FontSize',text_font_size)
            end
            count = count + 1;
        end
    end % for
    orient tall
    if saveit
        [p,n,e] = fileparts(fig_file_name);
        saveas(gcf,[n '_projections'],'png')
        close
    end
    
end
