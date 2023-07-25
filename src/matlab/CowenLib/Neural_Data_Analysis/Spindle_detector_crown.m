function [spindle_times_sec, PARAM, F] = Spindle_detector_crown(LFP,sFreq,sleep_intervals,PARAM)
% INPUT
%
% npoints x 2 col matrix. 1st col is time in seconds. 2nd col is the EEG
% data. Presumed to be in uV.
% sFreq = the sampling frequency of the data.
% sleep_intervals = the start and end times of each contiguous block of
% sleep Seconds.
% params: parameters for detection - a structure. Will change between
% subjects.
%
% PARAM.sigma_range = [10 15]
%
% CROWN 2019. (small mods by Cowen)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PLOT_IT = false;
if nargout == 0
    PLOT_IT = true;
end

if nargin < 3 || isempty(sleep_intervals)
    sleep_intervals = [0 Rows(LFP)/sFreq];
end

if size(LFP,2) ~= 2
    error('must have 2 col matrix')
end

if nargin < 4
%     PARAM.upper_thresh_std = 2.5; %number of st. deviations above the trimmed mean to trigger detection
%     PARAM.lower_thresh_std = 2; %number of st. deviations above the trimmed mean to trigger detection
    PARAM.upper_thresh_std = 3.5; %number of st. deviations above the trimmed mean to trigger detection
    PARAM.lower_thresh_std = 2.0; %number of st. deviations above the trimmed mean to trigger detection
    
    PARAM.min_dur_s = 0.5; %must remain above for this amount of time
    PARAM.max_dur_s = 2; %cannot exceed this amount of time: Cowen - 2 seems low, but hardly any are longer than 2 so probably does not matter.
    
    PARAM.merge_thresh_s = 0.2;
    PARAM.Sigma_range = [9 16];
    
    PARAM.frex_min=10;
    PARAM.frex_max=15;
    
    PARAM.upperpercent=90; %trimmed mean- this has helped a lot
    PARAM.lowerpercent=10;
    
    PARAM.spec_freqs = 2:.25:20; %parameters for the PSDs
    
end
LFP = double(LFP);
% LFP = gpuArray(LFP);
%5/2019
%changing to make an "actual function"
%parmeters that can be tweaked:

spin_minimum_inter_interval_period_sec = []; % I used this before but I thought result were better with this empty
spindle_times_sec = [];

count=1;

d = designfilt('bandpassiir','FilterOrder',10, ...
    'HalfPowerFrequency1',PARAM.Sigma_range(1),'HalfPowerFrequency2',PARAM.Sigma_range(2), ...
    'SampleRate',sFreq,'DesignMethod','butter');

filt_sig = filtfilt(d,LFP(:,2)); %filtered to spindle band
% filt_sig = gather(filt_sig);
as = abs(hilbert(filt_sig));
smoothed_power(:,1) = LFP(:,1);
hanwin = hanning(round(sFreq*.2)); %raising this to .2 to see if it will make the envelope less up and down-y
smoothed_power(:,2) = convn(as.^2,hanwin/sum(hanwin),'same'); %% hanning might be increasing power- doesnt sum to 1 divide by sum of hanning

%%
SleepPower = Restrict(smoothed_power,sleep_intervals);

maxpow = prctile(SleepPower(:,2), PARAM.upperpercent);
minpow = prctile(SleepPower(:,2), PARAM.lowerpercent);

trimmedpowerIX = SleepPower(:,2) > minpow & SleepPower(:,2) < maxpow;

powstd = std(SleepPower(trimmedpowerIX,2));
mean_power = mean(SleepPower(trimmedpowerIX,2));

lower_spin_thresh = mean_power + powstd * PARAM.lower_thresh_std; %these will be in standard deviations
upper_spin_thresh = mean_power + powstd * PARAM.upper_thresh_std;

F.total_time_asleep_s = sum(sleep_intervals(:,2)-sleep_intervals(:,1));
F.psd_frex = PARAM.spec_freqs;
F.time_max_power_sec = [];


for isleep=1:Rows(sleep_intervals)
    SleepIX = LFP(:,1)>sleep_intervals(isleep,1) & LFP(:,1)<sleep_intervals(isleep,2);
    
    [spin_above_times, ~] = find_intervals(smoothed_power(SleepIX,:), upper_spin_thresh, lower_spin_thresh, ...
        PARAM.min_dur_s, spin_minimum_inter_interval_period_sec);
    
    if ~isempty(spin_above_times)
        
        for ispin= 1:Rows(spin_above_times)
            spinintervalIX = LFP(:,1)>spin_above_times(ispin,1) & LFP(:,1)<spin_above_times(ispin,2);
            putative_spindle = LFP(spinintervalIX,:);
            [pxx,frex] = pburg(double(LFP(spinintervalIX,2)),40,PARAM.spec_freqs,sFreq);
            [~, ix] = max(pxx);
            peakfrex = frex(ix);
            
            if peakfrex > PARAM.frex_max || peakfrex < PARAM.frex_min % make sure peak it where you want it
                continue
            end
            
            spinlength=spin_above_times(ispin,2) - spin_above_times(ispin,1);
            if spinlength < PARAM.min_dur_s || spinlength > PARAM.max_dur_s
                continue
            end
            
            if max(putative_spindle(:,2)) > 500 ||  min(putative_spindle(:,2)) < -500 % get rid of artifacts
                continue
            end
            
            if PLOT_IT
                plotinterval = LFP(:,1) > spin_above_times(ispin,1)-1 & LFP(:,1) < spin_above_times(ispin,2)+1;
                
                figure
                subplot(3,1,1)
                yyaxis left
                plot(LFP(plotinterval,1),LFP(plotinterval,2),'k')
                axis tight
                hold on
                %                         plot(ECOG(plotinterval,1),filt_sig(plotinterval),'b')
                plot_vert_line_at_zero(min(LFP(spinintervalIX,1)));
                plot_vert_line_at_zero(max(LFP(spinintervalIX,1)));
                
                yyaxis right
                plot(smoothed_power(plotinterval,1),smoothed_power(plotinterval,2),'r')  % now 1= 1 second and this should be easy to estimate Hz from
                
                hline=refline(0,lower_spin_thresh);
                hline.LineWidth=0.75;
                hline2=refline(0,upper_spin_thresh);
                hline2.LineWidth=0.75;
                
                ylabel('uV')
                xlabel('Time(s)')
                title(sprintf('Duration %2.2f secs %1.1f frex',spinlength,peakfrex))
                
                subplot(3,1,2)
                %                 Spectrogram_spindle_LC(LFP(plotinterval,2), sFreq, 3:0.2:20, 'wavelet');
                Spectrogram_ripple(LFP(plotinterval,2), sFreq, 3:0.2:20, 'wavelet');
                %                 Spectrogram_spindle(LFP(plotinterval, 2), sFreq, 2:0.2:25);
                subplot(3,1,3)
                pburg(LFP(spinintervalIX,2),25,PARAM.spec_freqs,sFreq);
                
                grid off;
                pause
                %                 close
            end
            
            
            six= diff(spinintervalIX)> 0.5;
            eix=diff(spinintervalIX)< 0;
            spindle_times_sec(count,1:2)=[LFP(six,1) LFP(eix,1)];
            
            %             Spindle(count).values=LFP(spinintervalIX,2);
            
            F.peakfrex(count)=peakfrex;
            
            F.psd(count,:)=pxx;

            F.mean_power(count) = mean(smoothed_power(spinintervalIX,2));
            [F.max_power(count), F.max_power_ix(count)] = max(smoothed_power(spinintervalIX,2));
            [F.max_filt_sig(count), F.max_filt_sig_ix(count)] = max(filt_sig(spinintervalIX));
            F.time_max_power_sec(count) = spindle_times_sec(count,1) + F.max_power_ix(count)/sFreq;
            F.time_filt_sig_sec(count) = spindle_times_sec(count,1) + F.max_filt_sig_ix(count)/sFreq;
            
            count=count+1;
        end
    end
    
end
if length(F.time_max_power_sec)>2
    [F.peakpow_aligned_spindles, F.peakpow_aligned_spindles_x] = PETH_EEG_simple(LFP(:,1:2), F.time_max_power_sec, sFreq, sFreq,sFreq, 0);
    [F.peakfiltsig_aligned_spindles,~,F.peakfiltsig_filt_aligned_spindles_x_sec] = PETH_EEG_simple(LFP(:,1:2), F.time_filt_sig_sec, sFreq, sFreq,sFreq, 0);
    F.peakfiltsig_filt_aligned_spindles = PETH_EEG_simple([LFP(:,1) filt_sig(:)], F.time_filt_sig_sec, sFreq, sFreq,sFreq, 0);
    F.peakpow_aligned_spindles = single( F.peakpow_aligned_spindles);
    F.peakfiltsig_aligned_spindles = single( F.peakfiltsig_aligned_spindles);
    F.peakfiltsig_filt_aligned_spindles = single( F.peakfiltsig_filt_aligned_spindles);
end




