function NIDQ_Stimulate_IO(pulse_sequence_sec, varargin)
%  Stimulate
% Assumes you send in a sequence of times in seconds. A pulse at each time
% is created (with a value of 1) and then this is multiplied but the
% output_voltage. Biphasic pulses can be sent and they will be of the
% opposite polarity if deisred.
%% REQUIREMENTS: NI card and you may need to install the NIDQ-MX toolbox/package manager
% via add-ons in Matlab. It takes a while to install
%
% Cowen 2022
%%
% dlist = daqlist;
% DEFAULTS:
if nargin == 0
    pulse_sequence_sec = [.1 .4 .6 2 2.5:.4:10];
end
PLOT_IT = false;
output_voltage = 5;
sFreq = 50000;
ni_device_id = "PXI1Slot4";
ni_channel_number = 0;
individual_pulse_duration_sec = 0.002; %
biphasic_pulses = true;
biphasic_both_positive = true; % for WPI stimulators.
biphasic_interval_sec = 0.0005;
% Add some extra time for the last pulse.
stimulation_duration_sec = pulse_sequence_sec(end) + 2*(individual_pulse_duration_sec*2 + biphasic_interval_sec);

Extract_varargin;

n_samples_per_pulse = round(sFreq*individual_pulse_duration_sec);
n_samples_per_biphasic_shift = round(sFreq*biphasic_interval_sec) + n_samples_per_pulse;

% Stimulate ANALOG
d = daq("ni");
d.Rate = sFreq;
t_sec = [0:1/d.Rate:stimulation_duration_sec]';
sig = zeros(size(t_sec));

% ch.Range = [-5 5]; DOES NOT WORK - not sure why  - seems fixed at -10 10.
% probably does not amtter.
% convert the pulse sequences into digital pulses.
for ii = 1:length(pulse_sequence_sec)
    ix = find(t_sec >= pulse_sequence_sec(ii) ,1,'first');
    sig(ix) = 1;
    if ix < length(sig) -n_samples_per_pulse
        sig(ix:ix+n_samples_per_pulse) = 1;
    else
        sig(ix:end) = 1;
    end
end
if biphasic_pulses
    neg_sig = circshift(sig,n_samples_per_biphasic_shift)*-1;
    neg_sig(1:n_samples_per_biphasic_shift) = 0;
    sig = sig + neg_sig;
end
if biphasic_both_positive
    sig = abs(sig);
end
sig = sig*output_voltage;
% Send it out.
if PLOT_IT
    figure(1)
    clf
    plot(t_sec,sig)
    hold on
    pubify_figure_axis
end
% prepare for output
ch = addoutput(d,ni_device_id,ni_channel_number,"Voltage");
% Stimulate
write(d,sig);
