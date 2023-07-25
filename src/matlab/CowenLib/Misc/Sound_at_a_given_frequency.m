function [Aout, Fs] = Sound_at_a_given_frequency(desired_oscillation_fq_Hz, pulse_duration_s, desired_duration_s, sound_type, save_file)
% Generates a sound of a given frequency.
%%
PLOT_IT = false;
if nargin == 0
    desired_oscillation_fq_Hz = 80;
    pulse_duration_s = .005;
    desired_duration_s = 1200;
    sound_type = 'white noise';
end
if nargin < 4
    save_file = [];
end
cur_dir = fileparts(which('Sound_at_a_given_frequency'));
switch sound_type
    case 'white noise'
        [A,Fs] = audioread(fullfile(cur_dir, 'audiocheck.net_whitenoise.wav'));
    otherwise
        error('we have not figured out that sound type yet')
end
% make sure A is long enough.
if length(A)/Fs < desired_duration_s
    A = repmat(A,ceil(desired_duration_s),1);
end
% now create a
n_points_per_pulse = round(pulse_duration_s*Fs);
n_points_between_cycles = round(Fs/desired_oscillation_fq_Hz);
Z = zeros(size(A));
Z(n_points_between_cycles:n_points_between_cycles:end) = 1;
Z = movsum(Z,n_points_per_pulse);
Z(Z>0) = 1;
Aout = A.*Z;
npts = ceil(desired_duration_s*Fs);
Aout = Aout(1:npts);
if nargout == 0
    obj = audioplayer(Aout,Fs);
    play(obj)
end
if PLOT_IT
    figure
%     subplot(1,2,1)
    pwelch(abs(Aout),[],[],1:.2:100,Fs)
%     subplot(1,2,2)
%     pmtm(abs(Aout),[],1:.2:100,Fs)
end
