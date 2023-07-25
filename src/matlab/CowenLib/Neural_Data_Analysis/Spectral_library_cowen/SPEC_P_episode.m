function OUT = SPEC_P_episode(LFP, fq_range ,window_s, percentile_thresh, wavelet_width)
%% Define episodes of high power in a fq band.
% LFP - the output of Clean_LFP_Cowen. Load the PP file
% fq_range - frequencies to look at
% window_s - the windows in seconds over which to measure percent time and
%            rate
% percentile_thresh - The threshold for the percentile function. Data over
%                     it defines a p-episode
%wavelet_width - size of the wavelet used for decomposition
% examples:
% OUT = KT_P_episode(LFP,[4 140],10) - windows are 10 seconds, frequencies
% to look at are 4 and 140, percent_thresh and wavelet_width are default
% OUT = KT_P_episode(LFP,4) - 1 second windows, look at 4hz
% Mattenator 2016
PLOT_IT = true;
if nargin < 4
    percentile_thresh = 95;
    % 2 SD
end
if nargin < 5
    wavelet_width = 6;
    % A good number, 6 cycles
    % Compromise between time and frequency accuracy
end
if nargin < 3
    window_s = 1;
    % A good number, 6 cycles
    % Compromise between time and frequency accuracy
end


for f = 1:length(fq_range)
    [~, power, ~] = waveletdecomp(fq_range(f),LFP.values,LFP.sFreq,wavelet_width);
    %% NAN out the bad sections, as defined by Clean_LFP
    for i_interval = 1:size(LFP.bad_intervals,1)
        power(...
            floor(LFP.bad_intervals(i_interval,1))...
            :ceil(LFP.bad_intervals(i_interval,2)))...
            = NaN();
    end
    %% End Cleaning
    %% For now the threshold is a simple percentile of the power
    thresh = prctile(power,percentile_thresh);
    p_ixis = power > thresh;
    % Remove episodes less than one oscillation in length
    % To be safe, since it may be spurious
    ups = find(diff(double(p_ixis))>0);
    downs = find(diff(double(p_ixis))<0);
    durations = (downs-ups)./LFP.sFreq;
    short_ups_downs = [ups(durations < (1/fq_range(f)));downs(durations < (1/fq_range(f)))];
    % This next part I get the inverse, all the ups that are long enough. A
    % rate of episode occurance might be interesting, so I'll use this later
    long_ups = zeros(size(power));
    long_ups(ups(durations > (1/fq_range(f)))) = 1;
    for osc = 1:size(short_ups_downs,2)
        p_ixis(short_ups_downs(1,osc):short_ups_downs(2,osc)) = 0;
    end
    %% But then again what do I know? This may be a chunk we get rid of
    
    OUT.nan_pwer{f} = power;
    OUT.nan_pwer{f}(p_ixis) = nan();
    OUT.p_ixis{f} = p_ixis;
    % Simply the mean of the binary vector time 100. Percent of points within an episode
    OUT.percent_over{f} = mean(double(p_ixis))*100;
    % This chunk divides the recording into equal chunks and calculates the
    % percentage of time above the threshold within that chunk
    second_ixis = round(1:(LFP.sFreq*window_s):length(power));
    for i = 2:length(second_ixis)
        percent_over_per_second(i) = mean(double( p_ixis(second_ixis(i-1):second_ixis(i))))*100;
        rate_per_second(i)         =  sum(double(long_ups(second_ixis(i-1):second_ixis(i))))/window_s;
    end
    OUT.per_second.second_ixis{f}          = second_ixis;
    OUT.per_second.percent_over_per_second{f} = percent_over_per_second;
    OUT.per_second.rate_per_second{f}         = rate_per_second;
    if PLOT_IT == 1;
        figure
        plot(second_ixis,percent_over_per_second)
        hold on
        plot(second_ixis,rate_per_second)
        xlabel('Time(s)')
        legend('Percent of chunk over 95% Threshold','Episodes/sec')
        title(['P episodes of ' num2str(fq-range(f)) 'Hz'])
    end
    
end
OUT.fq_range = fq_range;
OUT.windos_s = window_s;



