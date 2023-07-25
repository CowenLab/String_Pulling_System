function Optimal_thresholds(Spike_files, destination_file, minimum_threhsold, maximum_sampling_rate_Hz)
%function Optimal_thresholds(Spike_files, destination_file, minimum_threhsold, maximum_sampling_rate_Hz)
%
% Determines the optimal thresholds by evaluating the data from a sample
% recording session recorded at a very low threshold (user's decision). 
% It looks at the distribution of the uVolt values above threshold at point 8
% on the waveform. It then chooses the threshold that is at the maximum allowable 
% sampling frequency for the channel. Ideally, it would filter OUT likely
% spike data so that the measure is based on the background noise. That may
% come later. If the rate is very low, the threshold will be set to the
% minimum threshold.
%
% INPUT
% Spike_files = cell array of spike files.
% destination_file = destination .cfg file to be loaded by Cheetah.
% minimum allowable threshold
% maximum_sampling_rate_Hz - maximum allowable sampling rate in Hz.
% 
% all inputs are optional. Defaults will be used if they are not specified.
% See the code.
%
% OUTPUT
%  a neuralynx configuration file. Load it when running cheetah.
%
% cowen 2004.
%
pt_on_wave = 8;

if nargin == 0
    Spike_files = sort(find_files('*.ntt'));
    if isempty(Spike_files)
        Spike_files = sort(find_files('*.nse'));
    end
end
if nargin <=1
    destination_file = 'New_Cheetah_Thresholds.cfg';
end
if nargin < 3
    minimum_threshold = 10;
end
if nargin < 4
    maximum_sampling_rate_Hz = 6.2;
end    
%
FieldSelection = [1 0 0 0 1];
ExtractHeader = 1; ExtractMode = 1;
ModeArray = [ ]; % Get allrecords.
%[TimeStamps, ScNumbers, CellNumbers, Params, DataPoints, NlxHeader] =  Nlx2MatSpike( fileList{ifile}, FieldSelection, ExtractHeader, ExtractMode, t1(wi) );
% filter out the noise and coincident spikes.
fp = fopen(destination_file,'w');
for ifile = 1:length(Spike_files)
    [p,n,e] = fileparts(Spike_files{ifile});
    [ts,wv,NlxHeader] =  Nlx2MatSpike( Spike_files{ifile}, FieldSelection, ExtractHeader, ExtractMode );
    H = Read_nlx_header(NlxHeader);
    wv = permute(wv,[3 1 2]);
    wv = reshape(wv,size(wv,1),1,size(wv,2));
    wv = wv .* H.ADBitVolts * 1e6; % Convert to uVolts.
    % Load a coincidence file if it exists. Probably not important at all.
    afile = fullfile(p,['Coincident_' n '.tstxt']);
    if exist(afile)
        loaded_ts = load(afile);
        [ts,goodidx] = setdiff(ts,loaded_ts);
        wv = wv(goodidx,:,:);
        disp (['deleted ' num2str(length(loaded_ts)) ' coincident spikes'])
        clear loaded_ts goodidx;
        pack
    end

    afile = fullfile(p,['Noise_' n '.tstxt']);
    if exist(afile)
        loaded_ts = load(afile);
        % Just look at the noise. Ignore anything spikey.
        [ts,goodidx] = intersect(ts,loaded_ts);
        wv = wv(goodidx,:,:);
        disp (['included ' num2str(length(loaded_ts)) ' noise spikes'])
        clear loaded_ts goodidx;
        pack
    end
    
    % Now that the data is cleaned up, let's look at the noise
    % distribution...
    s = size(wv);
    if s(2) > 1 % Tetrodes 
        [h,x] = hist(squeeze(Vector(wv(:,1:end,pt_on_wave))),min(wv(:,1,pt_on_wave)):1:max(wv(:,1,pt_on_wave)));
        h = h/s(2); % This converts it to samples per channel.
    else
        [h,x] = hist(squeeze(wv(:,1,pt_on_wave)),min(wv(:,1,pt_on_wave)):1:max(wv(:,1,pt_on_wave)));
    end
    % ignore the histogram before 0. We are not interested in this as we
    % won't put the threshold below 0. (no negative thresholds)
    h = h(2:end); x = x(2:end); %
    whole_cumsum = cumsum(h(end:-1:1));
    rate_cumsum = whole_cumsum./((ts(end) - ts(1))/1e6); % Converts to threshold crossing rate
    rate_cumsum = rate_cumsum(end:-1:1); % reverses to a more logical order of increasing threshold
    % find the point where the rate exceeds threshold.
    idx = find(rate_cumsum > maximum_sampling_rate_Hz);
    if isempty(idx)
        optimal_threshold = minimum_threshold;
    else
        idx = idx(end); % Find the last point above threshold
        optimal_threshold = round(x(idx));
    end
    disp(optimal_threshold)
    % Send it off to the configuration file.
    fprintf(fp,'-Select %s\n',H.NLX_Base_Class_Name);
    fprintf(fp,'\t-ThreshVal %i\n',optimal_threshold);
    fprintf(fp,'\n');

    if 0
        figure
        subplot(1,2,1)
        plot(x, rate_cumsum)
        hold on 
        plot([optimal_threshold optimal_threshold],[0 max(rate_cumsum)],'r')
        title([n ' THRESH: ' num2str(optimal_threshold)])
        mn = mean(squeeze(wv(:,1,:)));
        sd = std(squeeze(wv(:,1,:)));
        subplot(1,2,2)

        plot(mn);
        hold on 
        plot(mn+sd,'r');
        plot(mn-sd,'r');
        plot([0 32],[optimal_threshold optimal_threshold],'k')
        
        pause
        %saveas(gcf,['Noise_baseline_' n],'png')
        %close
    end
end
fclose(fp)