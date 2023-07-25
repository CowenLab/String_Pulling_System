function spectcoher = SPEC_coherence_cohen(sig1, sig2, sFreq, freqs2use, window_size_pts)
% Spectral coherence - binned.
% Modified from Cohen, Ch 26.
% this does not appear to work any better than mscohere. I would recommend
% this instead for now.
% Cowen 2016
%%%%%%%%%%%%%%%%%%%%%
PLOT_IT = false;
if nargin == 0
    % Generate artificial data for testing.
    PLOT_IT = true;
    sFreq = 1000;
    freqs2use = [2:180];
    window_size_pts = sFreq*2;
    duration_sec = 20;
    gain_modulation_fq_factor = [1 .1 ; 1 .1 ; 1 .1 ]'; % should be divisible into the associated value in Frequencies.
    %gain_modulation_fq_factor = [0  ; 0  ];
    noise_level = 0.1;
    frequencies = [8 15 40 ];
    [sig1] = Artificial_LFP(sFreq, duration_sec, frequencies, gain_modulation_fq_factor, noise_level );
    frequencies = [3 15 50 ];
    [sig2] = Artificial_LFP(sFreq, duration_sec, frequencies, gain_modulation_fq_factor, noise_level );
    % Add a phase lag to sig2...
    sig2 = circshift(sig2,[round(sFreq/5) 0]);
    
    frequencies = [12 23 54 ];
    [sig1b] = Artificial_LFP(sFreq, duration_sec, frequencies, gain_modulation_fq_factor, noise_level );
    frequencies = [7 33 54 ];
    [sig2b] = Artificial_LFP(sFreq, duration_sec, frequencies, gain_modulation_fq_factor, noise_level );
    
    sig1 = [sig1 sig1b];
    sig2 = [sig2 sig2b];
    
end
time = -1:1/sFreq:1;
BADIX = isnan(sig1 + sig2);
if any(BADIX)
    disp('Nans in data. This will screw things up. Converting nans to 0. Still not a good idea.')
    sig1(BADIX) = 0;
    sig2(BADIX) = 0;
end

% Convert the data to blocks for processing IF the user only passes in vector time series data. Otherwise assume blocks..
if min(size(sig1)) == 1
    overlap = 0;
    sig1 = Time_series_to_blocks(sig1, window_size_pts, overlap);
    sig2 = Time_series_to_blocks(sig2, window_size_pts, overlap);
end
n_blocks = size(sig2,2);
%%
% wavelet and FFT parameters
half_wavelet  = floor((window_size_pts-1)/2);
n_wavelet     = window_size_pts;
n_data        = window_size_pts*n_blocks;
n_convolution = n_wavelet+n_data-1;
num_cycles    = logspace(log10(2),log10(sFreq/5),length(freqs2use));

% data FFTs
data_fft1 = fft(reshape(sig1,1,n_data),n_convolution);
data_fft2 = fft(reshape(sig2,1,n_data),n_convolution);

%% initialize
% spectcoher = zeros(length(freqs2use),length(times2save));
spectcoher = zeros(length(freqs2use),size(sig1,2));

for fi=1:length(freqs2use)
    
    % create wavelet and take FFT
    s = num_cycles(fi)/(2*pi*freqs2use(fi));
    wavelet_fft = fft( exp(2*1i*pi*freqs2use(fi).*time) .* exp(-time.^2./(2*(s^2))) ,n_convolution);
    
    % phase angles from channel 1 via convolution
    convolution_result_fft = ifft(wavelet_fft.*data_fft1,n_convolution);
    convolution_result_fft = convolution_result_fft(half_wavelet+1:end-half_wavelet);
    convolution_result_fft = convolution_result_fft(1:end-1);
    sig1c = reshape(convolution_result_fft,window_size_pts,n_blocks)';
    
    % phase angles from channel 2 via convolution
    convolution_result_fft = ifft(wavelet_fft.*data_fft2,n_convolution);
    convolution_result_fft = convolution_result_fft(half_wavelet+1:end-half_wavelet);
    convolution_result_fft = convolution_result_fft(1:end-1);
    
    sig2c = reshape(convolution_result_fft,window_size_pts,n_blocks)';
    
    % compute power and cross-spectral power
    spec1 = mean(sig1c.*conj(sig1c),2);
    spec2 = mean(sig2c.*conj(sig2c),2);
    specX = abs(mean(sig1c.*conj(sig2c),2)).^2;
    % compute spectral coherence
    spectcoher(fi,:) = (specX./(spec1.*spec2))';
    fprintf('%d,',freqs2use(fi));
    % See ch 26 Cohen book. Also  - Itried imaginary coherence - could not
    % get it to work. Apparently, neither could cohen as he commented this
    % code out.
end
%%
if PLOT_IT
    subplot(2,1,1)
    imagesc([],freqs2use,spectcoher)
    axis xy
    colorbar
    subplot(2,1,2)
    Cxy = [];
    for ii = 1:size(sig1,2)
        [Cxy(ii,:)] = mscohere(sig1(:,ii),sig2(:,ii),hanning(window_size_pts/4),[],freqs2use,sFreq);
    end
    imagesc([],freqs2use,Cxy')
    title('REsult from mscohere')
    axis xy
    colorbar
end