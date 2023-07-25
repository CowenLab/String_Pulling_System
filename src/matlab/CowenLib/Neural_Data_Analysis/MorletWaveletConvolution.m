function OUT = MorletWaveletConvolution(dat,times,sr,trials,min_freq,max_freq,num_frex)

% Define wavelet parameters
EEG.pnts = length(dat);
time = -1:1/sr:1;
frex = logspace(log10(min_freq),log10(max_freq),num_frex);
s = logspace(log10(3),log10(10),num_frex)./(2*pi*frex);
% Define convolution parameters
n_wavelet = length(time);
n_data = EEG.pnts*trials;
n_convolution = n_wavelet+n_data-1;
n_conv_pow2  = pow2(nextpow2(n_convolution));
half_of_wavelet_size = (n_wavelet-1)/2;
eegfft = fft(reshape(dat,1,EEG.pnts*trials),n_conv_pow2); %get FFT of data
eegpower = zeros(num_frex,EEG.pnts); % frequencies X time X trials
baseidx = [1 length(EEG.pnts)]; %dsearchn(times,[0 max(times)]');
% Loop through frequencies and compute synchronization
for fi=1:num_frex
    wavelet = fft( sqrt(1/(s(fi)*sqrt(pi))) * exp(2*1i*pi*frex(fi).*time) .* exp(-time.^2./(2*(s(fi)^2))) , n_conv_pow2 );
    % Convolution
    eegconv = ifft(wavelet.*eegfft);
    eegconv = eegconv(1:n_convolution);
    eegconv = eegconv(half_of_wavelet_size+1:end-half_of_wavelet_size);
    % Average power over trials (baseline transform)
    temppower = mean(abs(reshape(eegconv,EEG.pnts,trials)).^2,2);
    eegpower(fi,:) = 10*log10(temppower./mean(temppower(baseidx(1):baseidx(2))));
end

OUT.eegpower = eegpower;