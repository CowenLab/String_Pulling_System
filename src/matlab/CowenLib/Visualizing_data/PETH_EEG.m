function [M, x_axis, fh, OUT, EEG_sec_data] = PETH_EEG(EEG_sec_data, sFreq ,alignments_ts_sec, time_before_sec, time_after_sec, option, option_parameters)
% Create a PETH of continuous EEG data around a given vector of events.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function [M, x_axis, fh, OUT] = PETH_EEG(EEG_sec_data, sFreq ,alignments_ts_sec, time_before_sec, time_after_sec, option, option_parameters)
% It is assumed that all units
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
%  EEG_sec_data. 2 col: 1st col time in sec, second col the data. The timestamps associated with each record are assumed to correspond to each rec.
%     first timestamp if the eeg data. THis does not have to be continuous. For instance, you could have
%     a chunk of data from 100 to 1000 and another from 30000 to 40000. This works as long as no alighnments_ts_sec
%     fall outside of these ranges.
%
%  the sampling frequency of the data.
%
%  the spacing in timestamps between the datapoints. spacing is assumed to be uniform.
%  alignments_ts_sec    - a ts object or vector of times from which spike_times_ts should
%                   be aligned.
%  time_before_sec - time before the alignment
%  time_after_sec  - time after the alignment.
%  option          - miscellaneous options:
%                     empty, do nothing
%                     'sta_plot' = plot a PETH type plot
%                     'density_plot' = plot a density type plot
% To DO:
%                     'units' - and a corresponding option parameter of say
%                     'msec'
%
%
% OUTPUT:
%  M - a matrix with the CSC records aligned
%  x_axis - the x axis of the plot
%  fh - a list of figure handles
%  OUT - output (typically a structure) from processing the optional
%  commands.
%  EEG_sec_data - if the user wants the original data used for the
%  alignments. This is useful if the program has to be run mulitple times
%  with different parameters (e.g. LFP and PSD) but uses the same data. The
%  user can run PETH_EEG the first time with the data file and the next
%  time with EEG_sec_data so that the data file does not need to be
%  reloaded.
%
%
% TODO: Make it accept multiple columns of input data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 11/20/02
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EEG_filename = [];
M = [];
fh = [];
x_axis = [];
OUT = [];

if nargin < 6
    option = {};
end
if ~iscell(option)
    % Make option into a cell array if it is not already.
    tmp{1} = option;
    clear option;
    option = tmp;
end
if isempty(sFreq)
    error (' You must supply a sampling rate and it BETTER BE CORRECT OR YOU ARE IN TROUBLE!!!')
end

if isa(alignments_ts_sec,'ts')
    alignments_ts_sec = Data(alignments_ts_sec)/10000;
end
if isempty(alignments_ts_sec)
    disp('No alignments specified.')
    
    return
end
if iscell(EEG_sec_data)
    for ii = 1:length(EEG_sec_data)
        M{ii} = PETH_EEG(EEG_sec_data{ii}, sFreq ,alignments_ts_sec,time_before_sec,time_after_sec,option);
    end
    return
end
NAN_IX = isnan(alignments_ts_sec);
if any(NAN_IX)
    %disp('nans in the alignments')
    alignments_ts_sec(NAN_IX) = [];
end

% events_not_in_order = false;
% if any(alignments_ts_sec ~= unique(alignments_ts_sec))
%     disp('alignments are either not unique or in order')
%     [alignments_ts_sec sort_ix] = unique(alignments_ts_sec);
%     events_not_in_order = true;
% end

% Remove nans:
%alignments_ts_sec(isnan(alignments_ts_sec)) = []; 

time_before_sec = abs(time_before_sec); % in case they passed in a negative number

if ischar(EEG_sec_data)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % The user passed in a filename so load it and do the dance.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    EEG_filename = EEG_sec_data;
    % load about 1/2second before and after the data to ensure that the entire period is loaded.
    range_to_load_ts = [alignments_ts_sec(:)*1e6 - time_before_sec*1e6 - .5e6, alignments_ts_sec(:)*1e6+time_after_sec*1e6 + .5e6];
    % intervals_us = [alignments_ts_sec(:)*1e6-2*time_before_sec*1e6  alignments_ts_sec(:)*1e6+2*time_after_sec*1e6];
    %[T, EEG_sec_data] = Read_CR_files({EEG_filename}, sFreq, range_to_load_ts,{'reref_global_median'});
    [T, EEG_sec_data] = Read_CR_files({EEG_filename}, sFreq, range_to_load_ts);
    if isempty(EEG_sec_data)
        error(['Could not get the data in ' EEG_filename])
    end
    % Read the header after loading the data as Read_CR_Files will unzip
    % any zipped Ncs files if there are any.
    try
        hdr = Read_nlx_header(EEG_filename);
        convert_to_mV = hdr.ADBitVolts * 1000;
        OUT.ylabel_str = 'mV';
    catch ME
        ME.stack
       
        convert_to_mV = 1;
        disp('Could not convert to mV')
        OUT.ylabel_str = 'A/D bits';
    end
    EEG_sec_data = [T/1e6, EEG_sec_data*convert_to_mV];
    usec_per_sample = 1e6/sFreq;
else
    usec_per_sample = 1e6/sFreq;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter out 60 Hz noise (and harmonics) if desired.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ismember('rectify', option)
    EEG_sec_data(:,2) = abs(EEG_sec_data(:,2));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ismember('filter_out_60hz', option)
    if sFreq > 60
        [b,a] = butter(5, [58 62]/(sFreq/2),'stop');
        EEG_sec_data(:,2) = filtfilt(b,a,EEG_sec_data(:,2));
    elseif sFreq > 120
        [b,a] = butter(5, [118 122]/(sFreq/2),'stop');
        EEG_sec_data(:,2) = filtfilt(b,a,EEG_sec_data(:,2));
    elseif sFreq > 180
        [b,a] = butter(5, [178 182]/(sFreq/2),'stop');
        EEG_sec_data(:,2) = filtfilt(b,a,EEG_sec_data(:,2));
    elseif sFreq > 240
        [b,a] = butter(5, [238 242]/(sFreq/2),'stop');
        EEG_sec_data(:,2) = filtfilt(b,a,EEG_sec_data(:,2));
    end
    disp('Filtered out 60Hz')
    if isnan(EEG_sec_data(:,2))
        error('Error while filtering the data')
    end
end
points_in_window = round(sFreq*(time_before_sec + time_after_sec)) + 1;
x_axis = linspace(-time_before_sec, time_after_sec,points_in_window);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%time_before_ts = time_before_sec*10; % Assumes old cheetah TimeStamps_us
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Align the TimeStamps_us by subtracting the point time from each record
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
n_alignments = length(alignments_ts_sec);
n_eeg_recs = size(EEG_sec_data,1);
M = zeros(n_alignments,points_in_window)*nan;
prev_idx = 1;
[sorted_alignments_ts_sec sort_ix] = unique(alignments_ts_sec);
for ii = 1:n_alignments
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Ignore points that go beyond the range
    % THIS ASSUMES THE TIMESTAMPS ARE IN ORDER.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ((sorted_alignments_ts_sec(ii) - time_before_sec) >= EEG_sec_data(1,1)) && prev_idx < size(EEG_sec_data,1)
        % Recall, there may be overlapping timestamps as one window may overlap with another. As a result
        % it necessary to take the LARGEST index that matches the timestamp. Thus, we need to use
        % binsearch only on the data following the previous find. This may even speed things up.
        % the new way. This ensures you only look at the data after the previous window so that
        % there is no overlap. This should also speed things up considerably.
        % The alternative is to just do this... idx = binsearch(EEG_sec_data(:,1), alignments_ts_sec(ii) - time_before_sec);
        idx = binsearch(EEG_sec_data(prev_idx:end,1), sorted_alignments_ts_sec(ii) - time_before_sec);
        idx = idx + prev_idx - 1;
        
        %prev_idx = idx + points_in_window - 1;
        % Was above, then I changed it.
        prev_idx = idx;
        
        if idx+points_in_window <= n_eeg_recs
            % Ignore points that go beyond the range
            M(ii,:) = EEG_sec_data(idx:(idx+points_in_window-1),2)';
        end
    else
        disp('WARNING: COULD NOT FIND INTERVAL IN THE DATA-- INTERVAL OUT OF RANGE')
    end
    
end
% SORT THINGS BACK
M = M(sort_ix,:);

if Rows(M) ~= length(alignments_ts_sec)
    error('Something is wrong, the rows in the triggered EEG are not the same as the passed in trigger times')
end

% If NAN's were in the alignments, then add them back to the matrix..
if any(NAN_IX)
    Mtmp = zeros(length(NAN_IX),size(M,2))*nan;
    Mtmp(~NAN_IX,:) = M;
    M = Mtmp;
end

%ix = find(~isnan(M(:,1)));
%M = M(ix,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The essential data has been collected (M), now process the options.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ismember('plot_offsets', option)
    offsets = option_parameters{ Find_string_in_ca(option, 'plot_offsets')};
else
    offsets = [0 1];
end
figure_count = 1;
for ii = 1:length(option)
    if isstr(option{ii})
        switch lower(option{ii})
            case {'sta_plot' 'sta_z_plot'}
                if length(option) > 1
                    fh(figure_count) = figure;
                end
                figure_count = figure_count + 1;
                
                label_str = '';
                if strcmpi(option{ii},'sta_z_plot')
                    % convert to Z scores
                    % This is a good idea if you wish to compare across days or segments. If not
                    % local or global fluctuations could mush out the mean you see.
                    mn = nanmean(M');
                    sd = nanstd(M');
                    Mz = (M-repmat(mn(:),1,size(M,2)))./repmat(sd(:),1,size(M,2));
                    M = Mz;
                    label_str = 'Z Scores';
                end
                %
                the_scale = 2;
                subplot(the_scale,1,1:(the_scale-1))
                set(gca,'YTick',1:size(M,1))
                imagesc(x_axis,[],M)
                % Change the color scale.
                caxis_min = prctile(M(find(~isnan(M))),1);
                caxis_max = prctile(M(find(~isnan(M))),99);
                caxis([caxis_min caxis_max])
                ylabel('Trial')
                plot_offsets(offsets)
                
                set(gca,'XTickLabel','')
                title(EEG_filename)
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Summarize.
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                subplot(the_scale,1,the_scale)
                if min(M(:)) > 0
                    barp(x_axis, nanmean(M)); % barp is my own bar using the patch call.
                else
                    plot(x_axis, nanmean(M)); % barp is my own bar using the patch call.
                    hold on
                    plot(x_axis, nanmedian(M),'g'); % barp is my own bar using the patch call.
                end
                axis tight
                %ylabel(['Mean ' OUT.ylabel_str])
                hold on
                plot(x_axis,prctile(M,80),'g:')
                plot(x_axis,prctile(M,20),'g:')
                plot(x_axis,nanmean(M) + Sem(M),'r')
                plot(x_axis,nanmean(M) - Sem(M),'r')
                %plot(x_axis,nanmean(M) + nanstd(M),'m:')
                %plot(x_axis,nanmean(M) - nanstd(M),'m:')
                xlabel('Time (sec), b=mean, g=median, r=SEM')
                title(label_str,'FontSize',8)
                plot_offsets(offsets)
                pubify_figure_axis
                subplot(the_scale,1,1:(the_scale-1)) % This puts the current axis back at the top
                pubify_figure_axis
                % so that the user can then put the title at the top of the figure instead of on
                % top of the bottom subplot.
                
            case 'density_plot'
                fh(figure_count) = figure;
                figure_count = figure_count + 1;
                
                caxis_min = prctile(M(find(~isnan(M))),0.5);
                caxis_max = prctile(M(find(~isnan(M))),99.5);
                M(find(M>caxis_max)) = caxis_max;
                M(find(M<caxis_min)) = caxis_min;
                Waveform_Density(M,[200 100]);
                fh = gcf;
                xt = get(gca,'XTick');
                l = linspace(min(x_axis), max(x_axis),length(xt));
                set(gca,'XTickLabel',l)
                title([EEG_filname ' EEG Density'])
                plot_offsets(offsets);
                
            case 'power_spectrum'
                fh(figure_count) = figure;
                figure_count = figure_count + 1;
                
                % Plot a mean spectragram of all of the trials.
                
                [p,conf, fq] = pmtm(M(1,:),[],[],sFreq);
                SPEC = zeros( size(M,1),length(p));
                for rr = 1:size(M,1)
                    fprintf('.')
                    [tmp,conf,fq] = pmtm(M(rr,:),[],[],sFreq);
                    SPEC(rr,:) = tmp';
                end
                good_fq_idx = find(fq < 350);
                SPEC = SPEC(:,good_fq_idx);
                fq = fq(good_fq_idx);
                
                subplot(1,2,1)
                imagesc(fq,[],SPEC)
                caxis([0 mean(SPEC(:)) + 2*std(SPEC(:))])
                pubify_figure_axis
                ylabel('Trial')
                title('Power spectra using pmtm')
                subplot(1,2,2)
                plot(fq,mean(SPEC))
                hold on
                plot(fq,mean(SPEC) + Sem(SPEC),'r')
                plot(fq,mean(SPEC) - Sem(SPEC),'r')
                axis tight
                xlabel('Frequency')
                pubify_figure_axis
                subplot(1,2,1)
                
            case 'windowed_psd'
                % This works - but it does pick up square pulses on all
                % frequency bands (e.g. bonking head). This does not happen
                % wiht spectrogram.
                
                % Best paramters for pwelch are 40Hz = win_size_sec of .2, win size idx of 300 and psd_window of 300. making the psd_window smaller did not help.
                % Fake data for testing: s = sin(0:200/sFreq:8*pi); M(1:50,2800:2988) = repmat(s*10+mean(M(:)),50,1);
                win_size_sec = .200; % size of the sliding window
                win_size_idx = round(sFreq*win_size_sec);
                psd_window = round(win_size_idx);
                %nfft = 256;
                %Fq_bands = [81 120; 67 80; 35 58; 21 34; 13 20; 9 12; 3 8];
                F_min = 3;
                F_max = 180; % Range of frequencies to analyze.
                
                shift_amount = round(win_size_idx/8);
                shift_amount_sec = win_size_sec/8;
                win_start = 1:shift_amount:(Cols(M)-win_size_idx);
                %F = zeros(sFreq/2 + 1,length(win_start));
                F = zeros(Rows(M), sFreq/2 + 1,length(win_start));
                Favg = zeros(sFreq/2 + 1,length(win_start));
                A = zeros(win_size_idx*2-1,length(win_start));
                Aavg = zeros(win_size_idx*2-1,length(win_start));
                A_y_axis = linspace(-win_size_idx/sFreq,win_size_idx/sFreq,Rows(A));
                %F_baseline = zeros(Rows(M), sFreq/2 + 1);
                %F_baseline2 = zeros(Rows(M), sFreq/2 + 1);
                %F_baseline3 = zeros(Rows(M), sFreq/2 + 1);
                % Determine the baseline by assuming the first window is a
                % control period.
                %for rr = 1:Rows(M)
                %    [F_baseline(rr,:),xF] = pwelch(M(rr,win_start(1):(win_start(1)+win_size_idx-1)),psd_window,[],sFreq,sFreq);
                %end
                %F_baseline_mean = nanmean(F_baseline);
                %F_baseline_std = nanstd(F_baseline);
                for rr = 1:Rows(M)
                    for wc = 1:length(win_start)
                        %[F(:,wc),Fconf,xF] = psd(M(rr,win_start(wc):(win_start(wc)+win_size_idx-1)),sFreq,sFreq,sFreq);
                        % Making the window smaller did seem to help. At least for the 40Hz stuff.
                        % [F(:,wc),Fconf,xF] = psd(M(rr,win_start(wc):(win_start(wc)+win_size_idx-1)),sFreq, psd_window,[]);
                        [F(rr,:,wc),xF] = pwelch(M(rr,win_start(wc):(win_start(wc)+win_size_idx-1)),psd_window,[],sFreq,sFreq);
                        %[F(:,wc),xF] = pyulear(M(rr,win_start(wc):(win_start(wc)+win_size_idx-1)),8,sFreq,sFreq);
                        %[F(:,wc) , xF] = pmtm(M(rr,win_start(wc):(win_start(wc)+win_size_idx-1)),[],sFreq,sFreq);
                        % Pxx = PMTM(X,NW,NFFT,Fs)
                        %                [Pxx,F] = PSD(X,NFFT,Fs,WINDOW,NOVERLAP)
                        % [Pxx,W] = PWELCH(X,WINDOW,NOVERLAP,NFFT,Fs)
                        %A(:,wc) = xcorr(M(rr,win_start(wc):(win_start(wc)+win_size_idx-1)),'coeff')';
                        %semilogy(xF,F);
                        %hold on;
                        %semilogy(xF,Fconf(:,1),'r:');
                        %semilogy(xF,Fconf(:,2),'r:');
                        %axis tight
                    end
                    % F = (F - repmat(F_baseline_mean(:),1,length(win_start)))./repmat(F_baseline_std(:),1,length(win_start));
                    fprintf('.')
                    %imagesc([],xF,log(F));
                    %Favg = Favg + F;
                    %Aavg = Aavg + A;
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Favg = squeeze(median(F)); % Median helps control for outliers - bonking artifact.
                %Fmd = squeeze(median(F));
                Favg_norm = Z_scores(Favg')'; % Z normalize across the duration of the trial. Not a great normalization, but it works - better than the median.
                
                %md = median(Favg');
                %fnorm = Favg - repmat(md',1,Cols(Favg));
                %Favg_normZZ = Z_scores(fnorm')';
                %Favg_norm = Favg - repmat(median(Favg')',1,Cols(Favg)); % Median helps limit the influence of outliers - a serios problem with EEG data.
                
                %Median subtraction
                %Z = Z_Scores(FavgMD')';
                % Normalize by the Z across trials.
                %FavgZ = (Favg - repmat(F_baseline_mean',1,Cols(Favg)))./repmat(F_baseline_std',1,Cols(Favg));
                % Interpolate so that the scale corresponds to the x axis of
                % the actual data.
                psd_x_axis = x_axis(win_start)+win_size_sec; %  aligned on the right of each bin.
                %Favg_interp = interp1(psd_x_axis,Favg',x_axis)';
                Favg_norm_interp = interp1(psd_x_axis,Favg_norm',x_axis)';
                
                %Aavg = Aavg/Rows(M);
                %%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if 0
                    for rr = 1:Rows(Fq_bands)
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        subplot(Rows(Fq_bands)+1, 1, rr)
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        idx = find( xF >= Fq_bands(rr,1) & xF <= Fq_bands(rr,2) );
                        imagesc(x_axis, xF(idx),(FavgZ_interp(idx,:)));
                        axis xy
                        if rr == 1
                            title(['Window Size ' num2str(psd_window) ' win size sec ' num2str(win_size_sec)])
                            ylabel('Hz')
                            plot_offsets(offsets)
                        end
                        if rr < Rows(Fq_bands)
                            set(gca,'XTickLabel','')
                        end
                        set(gca,'FontSize',7);
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    subplot(Rows(Fq_bands)+1,1,rr+1)
                    [the_end]   = max(psd_x_axis);
                    [the_start] = min(psd_x_axis);
                    startidx    = binsearch(x_axis,the_start);
                    endidx      = binsearch(x_axis,the_end);
                    %plot(x_axis(1:end-win_size_idx),mean(M(:,1:end-win_size_idx)),'k')
                    plot(x_axis,mean(M),'k')
                    xlabel('Time (sec)')
                    axis tight
                    plot_offsets(offsets)
                    
                    set(gca,'FontSize',7);
                    
                    subplot(Rows(Fq_bands)+1, 1, 1)
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Plot a more continuous representation of frequency space.
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                st_idx = binsearch(xF,F_min);
                ed_idx = binsearch(xF,F_max);
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %            Favg = Favg./repmat(median(Favg')',1,Cols(Favg));
                if 0
                    fh(figure_count) = figure;
                    figure_count = figure_count + 1;
                    subplot(4,1,1:3)
                    % interpolate so that the scaling is correct.
                    imagesc(x_axis,xF(st_idx:ed_idx),Favg_norm_interp(st_idx:ed_idx,:))
                    ylabel(['Fq (median subtraction, n = ' num2str(Rows(M)) ')'])
                    axis xy
                    subplot(4,1,4)
                    plot(x_axis,mean(M),'k')
                    hold on
                    plot(x_axis,median(M),'b')
                    xlabel('Time (sec), bk = mean, bl = median')
                    axis tight
                    plot_offsets(offsets)
                    set(gca,'FontSize',7);
                    subplot(4,1,1:3)
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%  Norm across fq bands    %% This may be obsolete.
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Favg2 = Favg_norm_interp;
                
                fh(figure_count) = figure;
                figure_count = figure_count + 1;
                subplot(4,1,1:3)
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %% interpolate so that the scaling is correct.
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                imagesc(x_axis,xF(st_idx:ed_idx),Favg2(st_idx:ed_idx,:))
                c = caxis;
                if (c(2) > 1.5)
                    caxis([1.5 inf])
                else
                    imagesc(x_axis,xF(st_idx:ed_idx), zeros(size(Favg2(st_idx:ed_idx,:))))
                end
                ylabel(['Fq in Z Scores > 1.5 (n = ' num2str(Rows(M)) ')'])
                set(gca,'XTickLabel','')
                
                axis xy
                subplot(4,1,4)
                plot(x_axis,mean(M),'k')
                hold on
                plot(x_axis,mean(M) + Sem(M),'r:')
                plot(x_axis,mean(M) - Sem(M),'r:')
                plot(x_axis,median(M),'b')
                xlabel('Time (sec), bk = mean, bl = median')
                axis tight
                plot_offsets(offsets)
                set(gca,'FontSize',7);
                subplot(4,1,1:3)
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if (0)
                    figure;
                    idx = find(xF >= F_min & xF <= F_max);
                    subplot(2,6,1:5)
                    % Centered on the middle of each window
                    imagesc(x_axis(win_start) + win_size_sec/2, xF(idx), Favg(idx,:));
                    axis xy
                    hold on
                    plot(x_axis,(mean(M)/(max(mean(M))))*10,'k')
                    ylabel('Hz')
                    % xlabel('Time (sec)')
                    
                    title(['Windowed PSD: ' num2str(win_size_sec) 'sec window, 1/4 step'])
                    subplot(2,6,6)
                    plot(mean(log(Favg(idx,:)')),1:length(idx))
                    axis off
                    
                    subplot(2,6,7:11)
                    imagesc(x_axis(win_start)+win_size_sec/2,A_y_axis,log(Aavg));
                    % Centered on the middle of each window
                    axis xy
                    %hold on
                    %plot(x_axis,(mean(M)-(mean(mean(M)))),'k')
                    ylabel('Offset (sec)')
                    xlabel('Time (sec)')
                    title(['Windowed acorr: ' num2str(win_size_sec) 'sec window, half step'])
                    subplot(2,6,12)
                    plot(mean(Aavg'),A_y_axis)
                    axis off
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    figure
                    % mesh looks better and actually pickst stuff up more nicely.
                    mesh(x_axis(win_start)+win_size_sec/2,A_y_axis,Aavg);
                end
                if nargout > 3
                    OUT.PSD_window_size_sec = win_size_sec;
                    OUT.PSD_shift_amount_sec = shift_amount_sec;
                    OUT.ACorr = Aavg;
                    OUT.ACorr_x_axis = x_axis(win_start);
                    OUT.ACorr_y_axis = A_y_axis;
                    OUT.Windowed_PSD_By_Trial = F;
                    OUT.Windowed_PSD = Favg2;
                    OUT.Windowed_PSD_x_axis = x_axis(win_start);
                    OUT.Windowed_PSD_y_axis = xF;
                    OUT.Note = 'x axis is centered on the right of the bin.';
                end
            case 'spectrogram'
                
                % Plot a mean spectrogram of all of the trials.
                % unlike windowed psd, this does not pick up square pulse noise
                % on all frequency bands.
                
                BANDS = [.5 3; 3.5 11; 13 24 ; 26 38 ; 40 55; 70 200];
                
                window = 128; noverlap = 120;nfft = 512; % oringina  Change noverlap to increase speed or decrease resolution.
                %window = 256; noverlap = 250; nfft = 256; % Change noverlap to increase speed or decrease resolution.
                %window = 128; noverlap = 120;nfft = 128; % Change
                %   noverlap to increase speed or decrease resolution.
                
                % NOTE: If you pass in frequency bands instead of an nfft
                % value, it takes MUCH LONGER TO PROCESS!!!
                [SPEC, fq, times,P] = spectrogram(M(1,:),window,noverlap,nfft,sFreq);
                %[tfr,T,F]=tfrwv(M(1,:)', 1:Cols(M)',40); % Time frequency toolbox function.
                %^ imagesc(t/sFreq,F,flipud(tfr));
                PSDs = zeros(size(P,1),size(P,2),size(M,1))*nan;
                % Get the raw specrograms.
                for rr = 1:size(M,1)
                    [S, fq, times,PSDs(:,:,rr)] = spectrogram(M(rr,:),window,noverlap,nfft,sFreq);
                end
                % Find a control period - before the event.
                sec_ix = find(times>=(time_before_sec-0.00001),1)
                mn = mean(mean(PSDs(:,2:sec_ix,:),3)')';
                sd = mean(std(PSDs(:,2:sec_ix,:),0,3)')';
                MN = repmat(mn,1,length(times));
                SD = repmat(sd,1,length(times));
                % Normalize the PSDs to Z Scores.
                %  This works better than doing it on a trial-by-trial basis as
                %  the global estimate of noise is more robust.
                nPSDs = PSDs - repmat(MN,[1 1 size(M,1)]);
                nPSDs = nPSDs./repmat(SD,[1 1 size(M,1)]);
                % What is the mean PSD?
                meanPSD = mean(nPSDs,3);
                % Look at groups of fq bands. A more specific hypothesis.
                meanPSDband = zeros(Rows(BANDS),length(times))*nan;
                meanPSDband2 = meanPSDband;
                stdPSDband = meanPSDband;
                semPSDband = meanPSDband;
                for iR = 1:Rows(BANDS)
                    fqix{iR} = find(fq >=BANDS(iR,1) & fq <BANDS(iR,2));
                    meanPSDband(iR,:) = mean(meanPSD(fqix{iR},:),1);
                    meanPSDband2(iR,:) = mean(mean(nPSDs(fqix{iR},:,:),3),1);
                    stdPSDband(iR,:) = mean(std(nPSDs(fqix{iR},:,:),0,3),1);
                    semPSDband(iR,:) = stdPSDband(iR,:)/sqrt(size(M,1)-1);
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                OUT.Windowed_PSD_By_Trial = PSDs;
                OUT.Windowed_PSD = meanPSD;
                OUT.Windowed_PSD_x_axis = times;
                OUT.Windowed_PSD_x_axis2 = linspace(min(x_axis), max(x_axis),length(times));
                OUT.Windowed_PSD_y_axis = fq;
                OUT.Windowed_PSD_bands = BANDS;
                OUT.Windowed_PSD_band_mean = meanPSDband;
                OUT.Windowed_PSD_band_sem = semPSDband;
                
                if nargout == 0
                    fh(figure_count) = figure;
                    figure_count = figure_count + 1;
                    subplot(10,1,1:5)
                    imagesc(times,fq,meanPSD)
                    axis xy
                    plot_offsets(offsets)
                    ylabel('Freq (Z normalized)')
                    title('Spectrogram, Z scores per trial')
                    subplot(10,1,6:10)
                    colors = {'b' 'r' 'g' 'k' 'c' 'm' 'y' 'b' 'r' 'g' 'k' 'c' 'm' 'y' };
                    for iR = 1:Rows(BANDS)
                        plot(times, meanPSDband(iR,:),colors{iR})
                        hold on
                    end
                    for iR = 1:Rows(BANDS)
                        plot_confidence_intervals( times, meanPSDband(iR,:),[ meanPSDband2(iR,:) + semPSDband(iR,:); meanPSDband2(iR,:) - semPSDband(iR,:)],colors{iR})
                    end
                    %mn = mean(BANDS');
                    for ii = 1:Rows(BANDS)
                        lg{ii} = sprintf('%3.1f %3.1f',BANDS(ii,:));
                    end
                    h = legend(lg);
                    set(h,'FontSize',8);
                    ylabel('Z Score')
                end
                
            case 'autocorrellation'
                % Limit the acorr to 500msec on either side.
                fh(figure_count) = figure;
                figure_count = figure_count + 1;
                usec_per_sample
                npts_on_either_side = round(500/(usec_per_sample/1000));
                midpt = size(M,2);
                A = zeros(size(M,1),size(M,2)*2-1);
                for ii = 1:size(A,1)
                    A(ii,:) = xcorr(M(ii,:),'coeff');
                end
                
                A(:,midpt) = nan;
                %A = Z_scores(A')';
                A = A(:,(midpt-npts_on_either_side):(midpt+npts_on_either_side+1));
                x_axis = linspace(-npts_on_either_side*usec_per_sample/1000,npts_on_either_side*usec_per_sample/1000,size(A,2));
                subplot(4,1,1:3)
                imagesc(x_axis,[],A)
                ylabel('Trial')
                title([EEG_filename ' Autocorrelation, coeff normalized per trial'])
                pubify_figure_axis
                subplot(4,1,4)
                plot(x_axis,nanmean(A))
                hold on
                plot(x_axis,nanmean(A) + Sem(A),'r')
                plot(x_axis,nanmean(A) - Sem(A),'r')
                axis tight
                xlabel('Lag (msec)')
                subplot(4,1,1:3)
            case {'filter_out_60hz' 'plot_offsets' 'rectify'}
            otherwise
                error('Incorrect option parameter')
        end
    end
    pubify_figure_axis
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargout == 0
    M = [];
end


function plot_offsets(offsets)
% Displays vertical lines on the plot. For event time plotting.
a = axis;

colors = {'w','c','y','g','m','r','b','w','c','m','k','c','b','r','g','m','k','c'};
hold on
for mc = 1:Rows(offsets)
    plot([offsets(mc,1) offsets(mc,1) ],[a(3) a(4)],colors{offsets(mc,2)},'LineWidth',2)
    plot([offsets(mc,1) offsets(mc,1) ],[a(3) a(4)],'k:','LineWidth',2)
end

end
