%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stimulate the vHC and evoke responses in the mPFC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2022
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PRM.biphasic = true; % set to false if using old WPI
PRM.biphasic_both_positive = false; % Both postive ONLY if using old WPI.
PRM.pulse_duration_ms = 0.5;
PRM.time_between_phases_ms = 0; % need some time - say .05ms if using the old orange WPI. 
PRM.n_pulses_per_burst = 5;
PRM.intra_burst_interval_ms = 2.5; % 400 Hz
PRM.time_between_bursts_sec = 2; % for experiment should be 2s
PRM.n_trials = 30;
% PRM.output_voltage = 2.32; % Look at the purple digitimer stimulator to translate this to uA.
PRM.output_voltage = 3.46; % This is equal to 300uA based on the translation - Abhi
%PRM.output_voltage = 5.76; % This is equal to 500uA based on the translation - Abhi
%%%%%%%% SIMPLE STIM EXPERIMNET...
pulse_sequence_sec = 0:PRM.intra_burst_interval_ms/1000:(1 + PRM.n_pulses_per_burst*PRM.intra_burst_interval_ms/1000);
pulse_sequence_sec = pulse_sequence_sec(1:PRM.n_pulses_per_burst);

tic;

% NOTE: we could just make a single train with bursts and send that out.
% This, however, makes it easier to break the train if things go wrong. It
% won't have the long-pulse interval precision though, but that does not
% matter.
for iT = 1:PRM.n_trials
    NIDQ_Stimulate_IO(pulse_sequence_sec, 'output_voltage', PRM.output_voltage, ...
        'individual_pulse_duration_sec', PRM.pulse_duration_ms/1000, ...
        'biphasic_pulses', PRM.biphasic, ...
        'biphasic_interval_sec', PRM.time_between_phases_ms/1000, ...
        'biphasic_both_positive', PRM.biphasic_both_positive);
    fprintf('%d ',iT);
    pause(PRM.time_between_bursts_sec)
end

%% Now load the local variance sequences...
% Second experiment - look at LV

% For the LV experiment.
LV.stim_files_path = 'C:\Users\CowenLab\Documents\GitHub\DANA\Data\Acute\20220218';
LV.stim_file = [];
LV.stim_files{1} = 'stim_times_20Hz_LV0.txt';
LV.stim_files{2} = 'stim_times_20Hz_LV0pt28.txt';
LV.stim_files{3} = 'stim_times_20Hz_LV1pt01.txt';
LV.stim_files{4} = 'stim_times_20Hz_LV1pt24.txt';
LV.n_trials = 10;
LV.time_betweeen_trials_sec = 10;

trial_order = repmat(1:length(LV.stim_files),1,LV.n_trials);

% load the stim times
for iF = 1:length(LV.stim_files)
    stim_times_sec{iF} = load(fullfile(LV.stim_files_path,LV.stim_files{iF}));
    % subtract the first time so that all start at time = 0 seconds
    stim_times_sec{iF} = stim_times_sec{iF} - stim_times_sec{iF}(1);
end

for iT = 1:length(trial_order)
    stim_times_for_trial_sec = stim_times_sec{trial_order(iT)};
    NIDQ_Stimulate_IO(stim_times_for_trial_sec, 'output_voltage', PRM.output_voltage, ...
        'individual_pulse_duration_sec', PRM.pulse_duration_ms/1000, ...
        'biphasic_pulses', PRM.biphasic, ...
        'biphasic_interval_sec', PRM.time_between_phases_ms/1000, ...
        'biphasic_both_positive', PRM.biphasic_both_positive);
    fprintf('%d ',iT);
    pause(LV.time_betweeen_trials_sec)
end
toc;
% make a record of the parameters of the experiment for posterity...
save(fullfile(LV.stim_files_path,'params_from_LV_exp.mat'))