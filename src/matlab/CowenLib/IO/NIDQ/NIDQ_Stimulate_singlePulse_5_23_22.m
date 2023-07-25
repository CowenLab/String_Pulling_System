%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stimulate the vHC and evoke responses in the mPFC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2022
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
%Save Stim file path and name input var
Stim_path='C:\SGL_DATA\vHPC_stim_mPFC_excitability_project\10847';
Stim_fileName='params_from_stim_exp_05_23_23.mat';

%Load Previous Stim File-no need to run the following parameters then

%load('C:\SGL_DATA\vHPC_stim_mPFC_excitability_project\params_from_stim_exp_05_12_23.mat');

%%
%Stimulation Parameters
PRM.biphasic = true; % set to false if using old WPI
PRM.biphasic_both_positive = false; % Both postive ONLY if using old WPI.
PRM.time_between_phases_ms = 0; % need some time - say .05ms if using the old orange WPI. 

PRM.pulse_duration_ms = 0.5;
PRM.n_pulses_per_burst = 1;
PRM.time_between_bursts_sec = 30; %s

PRM.PLOT_IT=false;

%Amplitude Range
PRM.output_current_min=1.18; % This is equal to 100uA based on the translation
PRM.output_current_max=4.60; %This is equal to 400uA 
PRM.output_current_step=0.228; %20uA

% Single Stim Arrays...
PRM.output_current_array_in_order=PRM.output_current_min:PRM.output_current_step:PRM.output_current_max; %Diff amplitudes
PRM.output_current_array=PRM.output_current_array_in_order(randperm(length(PRM.output_current_array_in_order)));%Randomize the stim amplitudes
PRM.n_trials = length(PRM.output_current_array);
pulse_sequence_sec=0.1; %Pulse second

%SAVE STIM FILE
save(fullfile(Stim_path,Stim_fileName))
%%
%%%%%%%%%%%%%%%%%%ONLY RUN FROM HERE %%%%%%%%%%%%%%%%%%

% NOTE: we could just make a single train with bursts and send that out.
% This, however, makes it easier to break the train if things go wrong. It
% won't have the long-pulse interval precision though, but that does not
% matter.
tic;
for iT = 1:PRM.n_trials
    NIDQ_Stimulate_IO(pulse_sequence_sec, 'output_voltage', PRM.output_current_array(iT), ...
        'individual_pulse_duration_sec', PRM.pulse_duration_ms/1000, ...
        'biphasic_pulses', PRM.biphasic, ...
        'biphasic_interval_sec', PRM.time_between_phases_ms/1000, ...
        'biphasic_both_positive', PRM.biphasic_both_positive,...
        'PLOT_IT',PRM.PLOT_IT);
    fprintf('%d - %d ',iT,PRM.output_current_array(iT));
    pause(PRM.time_between_bursts_sec)
end
toc;

%%%%%%%%%%%%%%%%%%

