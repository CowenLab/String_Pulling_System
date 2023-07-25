function REST = Rest_Events(Ripple_EEG_file, Theta_EEG_file,Spindle_EEG_file,EMG_file,TXY_text_file,epoch_times,thresholds)
% Computes important sleep state information given the EEG, EMG and
% position record.
%
%
% INPUT:
%   HC_EEG_file,Spindle_EEG_file,EMG_file - file names of ncs files.
%   TXY_text_file - a text file in which the first col is timestamp and the
%     next two columns are x and y position in pixels.
%   epoch_times - nx2 matrix of epoch times to consider.
%   thresholds is a structure.
%     thresholds.movement_pixels
%     thresholds.minimum_time_nonmoving_usec % the minimum amount of time
%       the rat has to be stationary to consider him being in 'REST'.
%     thresholds.spindles_uVolts
%     thresholds.REM_ThetaDeltaRatio
%     thresholds.Sia_ThetaDeltaRatio
%   Rest_Events tries to figure it out on its own.
%
%  presumes all times in all files are in usec.
%  all outputs are in usec.
%
% OUTPUT:
%   if no output is specified then this code generates some plots for the
%   interactive setting of thresholds and allows users to save these
%   settings to the current directory for future reference. This program
%   can then be re-run with those thresholds
% REST.Spindles.se_times - start and end times for spindles
% REST.Spindles.peak_time - time of peak of spindle
% REST.Spindles.nPeaks - number of peaks within each spindle (divide by duration to get frequency)
% REST.Spindles.likelihood - nx2 (time,likelihood) continuous measure of likelihood of a spindle at any point in time for rethresholding.
% REST.REM.se_times      - start and end times for REM.
% REST.Movement.se_times - start and end times for periods of movement.
% REST.SPW.se_times      - start and end times for sharpwaves.
% REST.SPW.nRipples      - number of ripple oscillations per SPW.
% REST.SPW.peak_time     - time of largest ripple peak in a spw
% REST.SIA.se_times      - start and end times for SIA (Biatta, and Bill).
% REST.Movement.se_times - start and end times for 
%   
%  cowen 2006
REST.Spindles.se_times_usec = []; %- start and end times for spindles
REST.Spindles.peak_time_usec = []; % time of peak of spindle
REST.Spindles.nPeaks = []; % number of peaks within each spindle (divide by duration to get frequency)
REST.Spindles.likelihood = []; % nx2 (time,likelihood) continuous measure of likelihood of a spindle at any point in time for rethresholding.
REST.REM.se_times_usec      = []; % start and end times for REM.
REST.Movement.se_times_usec = []; % start and end times for periods of movement.
REST.NonMovement.se_times_usec = []; % start and end times for periods of movement.
REST.NoMovementNoEMG.se_times_usec = []; % periods with no movement AND no EMG.
REST.SPW.se_times_usec      = []; % start and end times for sharpwaves.
REST.SPW.inter_spw_se_times_usec   = []; % start and end times for sharpwaves.
REST.SPW.nRipples      = []; % number of ripple oscillations per SPW.
REST.SPW.peak_time_usec     = []; % time of largest ripple peak in a spw
REST.SIA.se_times_usec      = []; % start and end times for SIA (Biatta, and Bill).
REST.Movement.se_times_usec = []; % start and end times for periods of movement
if nargout == 1
    plot_it = 1;
else
    plot_it = 0;
end
if isempty(thresholds)
    thresholds.movement_pixels = nan;
    thresholds.spindles_uVolts = nan;
    thresholds.EMG_uVolts = nan;
    thresholds.REM_ThetaDeltaRatio = nan;
    thresholds.REM_ThetaDeltaRatio_windsize = nan;
    thresholds.Sia_ThetaDeltaRatio = nan;
    thresholds.minimum_time_nonmoving_usec = 4e6;
end
% thresholds - position - in pixels - using a std or z score threshold may not be a good idea as this will vary between datasets. For a given experiment, the pixel motion threshold should be constant.
% thresholds - EEG and EMG - in uVolts - using a std or z score threshold
%    may not be a good idea as this will vary between datasets. For a given
%    experiment, the uVolt threshold should be constant.
%
% Movement
if ~isempty (TXY_text_file)
    [REST.Movement.se_times_usec REST.NonMovement.se_times_usec] = movement_times(TXY_text_file,epoch_times,thresholds.movement_pixels);
end
% EMG
if ~isempty (EMG_file)
    [REST.EMG.se_times_usec REST.NonEMG.se_times_usec] = emg_times(EMG_file,epoch_times,thresholds.EMG_uVolts);
end
% Determine periods when there is no EMG and NO movement
for ii = 1:size(REST.NonMovement.se_times,1)
    ix = find(REST.EMG.se_times_usec(:,1) > REST.NonMovement.se_times_usec(ii,1) & REST.EMG.se_times_usec(:,1) < REST.NonMovement.se_times_usec(ii,2));
    if isempty(ix)
        REST.NoMovementNoEMG.se_times_usec = [REST.NoMovementNoEMG.se_times_usec;REST.NonMovement.se_times_usec(ii,:)];
    else
        REST.NoMovementNoEMG.se_times_usec = [REST.NoMovementNoEMG.se_times_usec; REST.NonMovement.se_times_usec(ii,1) REST.EMG.se_times_usec(ii,1) ];      
    end  
end
% SPWS
if ~isempty (EMG_file)
    [T, EEG] = Read_CR_files(Ripple_EEG_file, 800, epoch_times, {'bandpass'}, {[100 300]});%, {'highpass'}, {20});
    EEG = EEG - mean(EEG);
    [st ed] = ripple_times(tsd(T/100,EEG),epoch_times,thresholds.SPW_uVolts);
    REST.SPW.se_times_usec = [st*100 ed*100]; 
    clear T EEG
    pack
end
% Spindles
if ~isempty (Spindle_EEG_file)
    [REST.Spindles.se_times_usec ] = Spindle_times_rat(Spindle_EEG_file,epoch_times,thresholds.spindles_uVolts);
end
% Theta periods - theta delta ratio
if ~isempty (Theta_EEG_file)
    [Tt, EEG_theta] = Read_CR_files(Theta_EEG_file, 50, epoch_times, {'bandpass'}, {[6 10]});
    [Td, EEG_delta] = Read_CR_files(Theta_EEG_file, 50, epoch_times, {'bandpass'}, {[2 4]});
    [Start_ts, End_ts] =  FindThetaStates_ThetaDeltaRatio(tsd(Tt/100,EEG_theta), tsd(Td/100,EEG_delta), thresholds.REM_ThetaDeltaRatio, thresholds.REM_ThetaDeltaRatio_windsize);
    REST.Theta.se_times_usec = [Data(Start_ts) Data(End_ts)]*100;
end