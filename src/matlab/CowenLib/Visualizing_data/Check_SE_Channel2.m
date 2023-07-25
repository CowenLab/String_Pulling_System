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
% OUTPUT
%   a summary sheet
% 
% cowen 2002
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
if nargin == 1
    timestamp_file = [];
end

start_and_end_time = [];
event_times = [];
subsample_limit = 120000;
title_string    = '';
text_font_size  = 8;
before_ts  = 500 * 1000;
after_ts   = 500 * 1000;
binsize_ts = 20 * 1000;
features_to_show = [];
saveit = 0;
ncols = 3;

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
    
    if ~isempty(start_and_end_time)
        try
            [t wv header] = Nlx2MatSE([n e],1,0,0,0,1,1, start_and_end_time(1),start_and_end_time(2));
        catch
            disp([n e ' failed']);
            return
        end
        total_spikes = length(t);

    else
        try
            [t header] = Nlx2MatSE([n e],1,0,0,0,0,1);
            total_spikes = length(t);
            if total_spikes>subsample_limit
                disp(['File has ' num2str(length(t)) ' records, subsampling (random).'])
                t = t(unique(round(rand(1,30000)*length(t))));
                [t wv] = Nlx2MatSE([n e],1,0,0,0,1,0,t);
                title_string = [title_string ' SubSampled ']
            else
                [t wv] = Nlx2MatSE([n e],1,0,0,0,1,0);
            end
        catch
            disp([n e ' failed']);
            return
        end
    end
   
else
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    % a timestamp and waveform file is specified.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    fig_file_name = timestamp_file;
    [p,n,e] = fileparts(fig_file_name);
    
    % Load in the timestamp file.
    tfp = fopen(timestamp_file, 'rb','b');
    if (tfp == -1)
        warning([ 'Could not open tfile ' timestamp_file]);
        return
    end
    ReadHeader(tfp);    
    t_to_get = fread(tfp,inf,'uint32');	%read as 32 bit ints    fclose(tfp);
    
    if ~isempty(start_and_end_time)
        idx = find(t_to_get > start_and_end_time(1) & t_to_get <= start_and_end_time(2) );
        t_to_get = t_to_get(idx);
    end
    % Subsample if necessary
    if length(t_to_get)>subsample_limit
        disp(['File has ' num2str(length(t_to_get)) ' records, subsampling (random).'])
        t_to_get = t_to_get(unique(round(rand(1,30000)*length(t_to_get))));
        title_string = [title_string ' SubSampled ']
    end
      
    [p,n,e] = fileparts(waveform_file);
    t_in_file = Nlx2MatSE([n e],1,0,0,0,0,0);
    [t idx] = intersect(floor(t_in_file/100), t_to_get);
    disp(['Found ' num2str(length(t)) ' of the ' num2str(length(t_to_get)) ' records in the waveform file. Loading.'])
    [t wv header] = Nlx2MatSE([n e],1,0,0,0,1,1, t_in_file(idx));
    total_spikes = length(t);
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
t = t(:); % Make sure the timestamps are a vertical col -- ts is not very smart.
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
subplot(nrows,ncols,1)

plot(1:32,mn)
hold on 
plot(1:32,mn+sd,'r')
[p, n, e] = fileparts( fig_file_name);

title([[n e] ' ' title_string ])
axis tight
subplot(nrows,ncols,2)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ISI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
HistISI(ts(t/100)); % New cheetah timestamps are in micorseconds. 
                    % Convert to .1msec old format for HistISI.
ylabel('nSpikes','FontSize',text_font_size);
xlabel('msec','FontSize',text_font_size)
axis tight
title ([num2str(length(t)) ' of ' num2str(total_spikes) ' spikes displayed'],'FontSize',text_font_size)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Autocorrelation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(nrows,ncols,3)

acorr_bin_msec = 4;
[histvals,x] = autocorr(t/100, acorr_bin_msec, 250); % This is peter's C autocorr

plot(x,histvals);			% show acorr

xlabel(['msec (' num2str(acorr_bin_msec) 'msec binsize)'],'FontSize',text_font_size)
ylabel('rate','FontSize',text_font_size)
title('Autocorr','FontSize',text_font_size)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Density plot. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot(nrows,ncols,4)
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
        Waveform_density(wv(rnds(1:10000),:),interpolate,limit);
        title('subsampled','FontSize',text_font_size)
    else
        Waveform_density(wv,interpolate,limit);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% wv(time) x wv(time+1) plot (how the waveform changes)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(nrows,ncols,5)
h = Waveform_time_dynamics_plot(wv);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Time and time + 1 plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(nrows,ncols,6)
d = diff(t/1000); % Convert to msec
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
plot(t,wv(:,8),'b.','MarkerSize',1)
hold on
plot(t,wv(:,validx),'m.','MarkerSize',1)
axis tight
xlabel('time','FontSize',text_font_size)
ylabel('Peak and Valley','FontSize',text_font_size)

%xlabel('amp(t)')
%ylabel('amp(t+1)')
if ~isempty(event_times)

    subplot(nrows,ncols,10:12)
    
    if ~isempty(event_times)
        PETH(t,event_times,[before_ts after_ts],binsize_ts);
    end
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
    a_dim = ceil(sqrt((nFeatures^2 - nFeatures)/2));
    count = 1;
    for iF = 1:length(features_to_show)
        for jF = (iF+1):length(features_to_show)
            [FeatureData1, FeatureNames1] = ...
                feval(['feature_', features_to_show{iF}], tsd(t,reshape(wv,size(wv,1),1,size(wv,2))), [1 0 0 0]);
            [FeatureData2, FeatureNames2] = ...
                feval(['feature_', features_to_show{jF}], tsd(t,reshape(wv,size(wv,1),1,size(wv,2))), [1 0 0 0]);
            
            subplot(a_dim,a_dim ,count)
            % Check to see if you have some integer data-- if so, ad some random noise to make it viewable.
            if Is_int(FeatureData2)
                FeatureData2 = FeatureData2 + rand(size(FeatureData2)) - .5;
            end
            if Is_int(FeatureData1)
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
