function  [Start_ts, End_ts] =  FindThetaStates_ThetaDeltaRatio(eeg_tsd_theta, eeg_tsd_delta, pow_threshold, winsize)
%   
%      [Start_ts, End_ts] =  FindThetaStates_ThetaDeltaRatio(eeg_tsd_theta, eeg_tsd_delta, pow_threshold, winsize)
%
%   Find time intervals in which the animal is presumably in 'theta state'.
%
%  Uses a crude local power estimate (envelope of theta-filtered eeg amplitude squared)
%  and determines a threshold so that the animal is a fraction time_fraction 
%  of the total time span in theta state. (the fraction of time is supposed to be determined
%  by fraction of time the animal spent 'in motion')
%
%  IN: eeg_tsd_theta       ...  tsd of FILTERED (6-10Hz) theta eeg
%      eeg_tsd_delta       ...  tsd of FILTERED (2-4Hz) delta eeg
%      pow_threshold       ... threshold for theta/delta power ratio (2 in Louie & Wilson, 2001) 
%      winsize             ... the number of data points to include for each smooth calculation (ex. 2 sec in Csicsvari et al., 1999)
%
% OUT: Start_ts, End_ts ... ts objects containing the start and end timestamps of a series 
%                           of intervals. Can be used directly as arguments for 
%                           the tsd/Restrict method
%
% PL  dec 99
%
% Theta/Delta power ratio is used to determine theta state
% Envelope of theta and delta is estimated using 'interp1'
% Power ratio is smoothed using 'smooth'
% Theta state is determined using smoothed theta/delta power.
% MT 2006-03-05
% cowen - made the tsd requirement optional - so users can bass in nx2
% matrices with time as the first and data as the second column.

MinGapLength = 10000;   % minimum gap length (LIA) between theta cycles (1 sec)
MinThetaInterval = 10000; % minimum length of a theta interval (1 sec)
if isdouble(eeg_tsd_theta)
    pow_theta = eeg_tsd_theta(:,2).^2;
    pow_delta = eeg_tsd_delta(:,2).^2;
    ts_eeg  = eeg_tsd_theta(:,1);
else
    pow_theta = Data(eeg_tsd_theta).^2;
    pow_delta = Data(eeg_tsd_delta).^2;
    ts_eeg  = Range(eeg_tsd_theta,'ts');
end
pow = pow_theta./pow_delta;
% Start, MT 2006-03-05
% Calculation of envelope for Theta
% 'spline' option of interp1 does not work well because ratio of theta/delta may become
% negative.  Use default option for interp1
diff_pow_theta = diff(pow_theta); % calculate diff
sign_diff_pow_theta = sign(diff_pow_theta); % convert it 1 (positive diff) and -1 (negative diff)
diff_sign_diff_pow_theta = diff(sign_diff_pow_theta); % obtain peak (-2) or bottom (2)
A = [0];
diff_sign_diff_pow_theta = cat(1,A,diff_sign_diff_pow_theta); % add 0 in the begining
ind_diff_sign_diff_pow_theta = find(diff_sign_diff_pow_theta == -2); % find index for peak
ts_eeg_peak_theta = ts_eeg(ind_diff_sign_diff_pow_theta); % ts of peak eeg point
pow_peak_theta = pow_theta(ind_diff_sign_diff_pow_theta); % power corresponding to peak ts
pow_theta_interp1 = interp1(ts_eeg_peak_theta, pow_peak_theta, ts_eeg);

% Calculation of envelope for Delta
diff_pow_delta = diff(pow_delta); % calculate diff
sign_diff_pow_delta = sign(diff_pow_delta); % convert it 1 (positive diff) and -1 (negative diff)
diff_sign_diff_pow_delta = diff(sign_diff_pow_delta); % obtain peak (-2) or bottom (2)
A = [0];
diff_sign_diff_pow_delta = cat(1,A,diff_sign_diff_pow_delta); % add 0 in the begining
ind_diff_sign_diff_pow_delta = find(diff_sign_diff_pow_delta == -2); % find index for peak
ts_eeg_peak_delta = ts_eeg(ind_diff_sign_diff_pow_delta); % ts of peak eeg point
pow_peak_delta = pow_delta(ind_diff_sign_diff_pow_delta); % power corresponding to peak ts
pow_delta_interp1 = interp1(ts_eeg_peak_delta, pow_peak_delta, ts_eeg);

pow_env_org = pow_theta_interp1./pow_delta_interp1; % Theta/Delta power ratio

% pow_ratio = smoothts(pow_ratio, 'g', 10, 1); % smoothing with gaussian window (smoothts)
% pow_ratio = tsmovavg(pow_ratio, 's', 10, 1); % smoothing with moving average (tsmovavg)

pow_env = smooth(pow_env_org, winsize); % smoothing with moving average

ts_env = ts_eeg;
% End, MT 2006-03-05

% [ts_env,pow_env, PeaksIdx] = PowerEnvelope(ts_eeg,pow);
% calculate power threshold from given time_fraction
%[pow_hist,xbins] = hist(pow_env,100);     
%pow_cpdf = cumsum(pow_hist)/sum(pow_hist);
%tail = find(pow_cpdf > 1-time_fraction);
%pow_threshold = xbins(tail(1))

% find intervals with thetapower above threshold
inth = find(pow_env > pow_threshold);
ii   = find(diff(inth) > 2);
start_i = [inth(1); inth(ii+1)];
end_i = [inth(ii); inth(end)];

S = ts_env(start_i);
E = ts_env(end_i);

% cut out gaps shorter than MinGapLength
i = 2;
while i < length(S)
  while (S(i) - E(i-1)) < MinGapLength & i < length(S)
    S(i) = [];
    E(i-1) = [];
  end
  i = i+1;
end

% cut out theta intervals shorter than MinThetaInterval
i=1;
while i <= length(S)
  while (E(i)-S(i)) < MinThetaInterval & i < length(S)
    S(i) = [];
    E(i) = [];
  end
  i = i+1;
end

Start_ts = ts(S);
End_ts = ts(E);

% make figure for visual inspection, MT 2006-03-05
figure;
plot(ts_env,pow_env_org);
hold on;
axis tight;
plot(ts_env,pow_env,'r');
startend_ts = [Data(Start_ts) Data(End_ts)];
plot(startend_ts',pow_threshold*ones(size(startend_ts))');
title('Theta state (horizontal line), Theta/Delta Power (blue), and Smoothed Theta/Delta Power (red)');
hold off;

figure;
if isdouble(eeg_tsd_theta)
    plot(ts_env,eeg_tsd_theta(:,2));
else
    plot(ts_env,Data(eeg_tsd_theta));
end

hold on;
axis tight;
startend_ts = [Data(Start_ts) Data(End_ts)];
plot(startend_ts',pow_threshold*ones(size(startend_ts))');
title('Theta state (horizontal line) and filtered theta EEG');
hold off;
