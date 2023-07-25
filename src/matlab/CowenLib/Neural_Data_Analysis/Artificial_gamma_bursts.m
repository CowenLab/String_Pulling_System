function [GB,T,FQ] = Artificial_gamma_bursts(fqs, n_cycles_per_burst, signal_dur_sec, time_between_bursts_sec, sFreq)
% Create intermittent burst like signals of different frequencies. A gap of
% no signal is between each 'burst'.
% It is left to the user to add noise or other signal to this after getting
% the output.
% OUTPUT
% GB - continuous signal with gamma bursts
% T - time in seconds
% FQ - the frequency of that burst.
%
% Call:
% Artificial_gamma_bursts([10 90 80 102], 40, 50, .2,2000)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 0
    Artificial_gamma_bursts([10 90 80 102], 40, 50, .2,2000)
    return
end
signal_dur_samples = signal_dur_sec*sFreq;
n_samps = signal_dur_sec*sFreq;
T = linspace(0,signal_dur_sec,n_samps);
sine_wave = [];
kern = [];
for iF = 1:length(fqs)
    % kern_size = kern_size 
    kern_dur_sec = n_cycles_per_burst/fqs(iF);
    kern_dur_samples = kern_dur_sec*sFreq;
    kern{iF} = hanning(kern_dur_samples)';
    sine_wave{iF} = sine_wave_by_duration_and_sFreq(fqs(iF),kern_dur_sec,sFreq);
    mix = min([length(kern{iF}) length(sine_wave{iF}) ]); % sometimes it's off by one
    kern{iF} = kern{iF}(1:mix);
    sine_wave{iF} = sine_wave{iF}(1:mix);
end
% now let's create the signal
end_sample = -1;
current_sample = 1;
samples_between_bursts = time_between_bursts_sec*sFreq;
GB = zeros(size(T));
FQ = zeros(size(T));
while end_sample < signal_dur_samples
    for iF = 1:length(kern)
        end_sample = current_sample + length(kern{iF})-1;
        if end_sample + 10 > signal_dur_samples
            break
        end
        GB(current_sample:end_sample) = kern{iF}.*sine_wave{iF};
        FQ(current_sample:end_sample) = fqs(iF);
        current_sample = end_sample + 1 + samples_between_bursts;
    end
end

if nargout == 0
    figure
    subplot(2,2,1)
    plot(T,GB)
    axis tight
    subplot(2,2,3)
    plot(T,FQ)
    xlabel('sec')
    ylabel('Hz')
    axis tight

    subplot(2,2,2)
    pwelch(GB,sFreq,sFreq/2,1:.2:max(fqs)+5,sFreq)
    axis tight

    subplot(2,2,4)

    [xc,lags] = xcorr(GB,GB,sFreq);
    plot(lags/sFreq,xc)
    plot_vert_line_at_zero
    axis tight

end
