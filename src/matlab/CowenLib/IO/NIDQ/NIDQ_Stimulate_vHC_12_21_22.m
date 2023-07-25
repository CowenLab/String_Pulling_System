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
PRM.output_voltage = 5; % This is equal to 300uA based on the translation - Abhi
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


toc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Theta Burst

PRM.biphasic = true; % set to false if using old WPI
PRM.biphasic_both_positive = false; % Both postive ONLY if using old WPI.
PRM.pulse_duration_ms = 0.25;
PRM.time_between_phases_ms = 0; % need some time - say .05ms if using the old orange WPI. 
PRM.n_pulses_per_burst = 3;
PRM.intra_burst_interval_ms = 5; % 200 Hz
PRM.time_between_bursts_sec = 0.125; % 8Hz theta
PRM.n_trials = 60;
% PRM.output_voltage = 2.32; % Look at the purple digitimer stimulator to translate this to uA.
PRM.output_voltage = 3.46; % This is equal to 300uA based on the translation - Abhi
%PRM.output_voltage = 5.76; % This is equal to 500uA based on the translation - Abhi

%%%%%%%% SIMPLE STIM EXPERIMNET...
pulse_sequence_sec = 0:PRM.intra_burst_interval_ms/1000:(1 + PRM.n_pulses_per_burst*PRM.intra_burst_interval_ms/1000);
pulse_sequence_sec = pulse_sequence_sec(1:PRM.n_pulses_per_burst);

for iT = 1:PRM.n_trials
    NIDQ_Stimulate_IO(pulse_sequence_sec, 'output_voltage', PRM.output_voltage, ...
        'individual_pulse_duration_sec', PRM.pulse_duration_ms/1000, ...
        'biphasic_pulses', PRM.biphasic, ...
        'biphasic_interval_sec', PRM.time_between_phases_ms/1000, ...
        'biphasic_both_positive', PRM.biphasic_both_positive);
    fprintf('%d ',iT);
    pause(PRM.time_between_bursts_sec)
end