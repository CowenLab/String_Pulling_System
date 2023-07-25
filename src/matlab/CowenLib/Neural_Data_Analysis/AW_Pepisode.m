function [pow,phase,P_episode_pow,P_episode_phase,Binary_matrix] = AW_Pepisode(data,freqs,wavelet_cycles,duration,srate,pthresh,Athresh)%,power_thresh)
%%  data = raw data to analyze

%% freqs = frequencies to analyze

%%  wavelet_cycles = c value to use (should be > 4)

%% duration = number of cycles of oscillation to threshold

%% power_thresh = percentile to threshold power values at.  originally a
%% variable, but now set at 95th percentile by incoporating J Caplan code
%% from calcPepisode


%outputs
%pow:  raw power
%P_episode_pow:  thresholded power values.  Size is Freqs X Times
%P_episode_phase: thresholded phase values  Size is Freqs X Times
%Binary_matrix:  Binary matrix indicating time frequency points in which
%the signal met P-episode criteria.  Size is Freqs X Times

%srate = 1000;  %%  should be standard 1000 Hz downsampled data
remHigh = find(data>Athresh(100));
remLow = find(data<Athresh(1));
[phase,pow]=multiphasevec2(freqs,data,srate,wavelet_cycles);

pow(:,remHigh) = NaN;
pow(:,remLow) = NaN;
% Determine power threshold for every freq
percentile = ceil(length(data) * power_thresh);
for f = 1:length(freqs)
    power_vals = sort(pow(f,:));
    pthresh(f) = power_vals(percentile);
    clear power_vals
end


%  temporarily convert 0 pow values to nan before log transforming.
zero_idx = find(pow ==0);  % find 0 values in pow
pow_nan = pow;
pow_nan(zero_idx) = NaN;  % convert 0 values in pow to NaN
%%% from eeg toolbox calcPepisode
%Blog = log10(double(B));

Blog = log10(double(pow_nan));  % ajw modified
Blog(zero_idx) = 0;  %  ajw added.  convert original zero values back to 0

%B = single(pow);
% calc the mean fit

Pm = mean(Blog,2);
%Pm = mean(B,2);

% get the fit

% IMPORTANT: chi_squarefit assumes that frequencies are
% logarithmically spaced!
[all,R2] = chi_squarefit(freqs,Pm);
all = all';
%all = chi_squarefit_old(freqs,Pm)';

% set the threshold
pthresh = all(:,951);

clear Blog all Pm pow_nan


%%%%  get matrix of values which are greater than power threshold
%matlabpool open
Binary_matrix = zeros(length(freqs),length(data));
for f = 1:length(freqs)
    idx = find(pow(f,:) > pthresh(f));
    Binary_matrix(f,idx) = 1;
    clear idx
end

%%% Impose cycles constraint
for y = 1:length(freqs)
    
    % parfor y = 1:length(freqs)
    power_values = Binary_matrix(y,:);
    osc_counter = 0;
    Oscillations = [];
    
    for z = 1:length(power_values)
        
        
        if z == 1
            a =   0;
        else
            a = power_values(z-1);
        end
        v = power_values(z);
        
        
        if v ==1 && a ==0
            osc_counter = osc_counter +1 ;
            
            osc_offset = min(find(power_values(z+1:end) == 0));
            
            Oscillations(osc_counter,1) = z;
            
            if isempty(osc_offset) ~=1
                
                Oscillations(osc_counter,2) = osc_offset + z -1;
            else
                Oscillations(osc_counter,2) = length(power_values);
            end
            
            
        end
    end
    
    period = 1/freqs(y);
    Dt =  round(period*srate*duration); %  1007 samples per second
    
    
    for r = 1:size(Oscillations,1)
        Osc_length = Oscillations(r,2)-Oscillations(r,1);
        if Osc_length < Dt
            Binary_matrix(y,Oscillations(r,1):Oscillations(r,2)) =0;
        end
    end
    
end
P_episode_pow = pow .* Binary_matrix;
P_episode_phase = phase .* Binary_matrix;
%matlabpool close

