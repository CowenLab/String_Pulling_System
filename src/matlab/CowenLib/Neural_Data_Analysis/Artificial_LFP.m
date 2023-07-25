function [L, INFO] = Artificial_LFP(sFreq, duration_sec, frequencies, gain_modulation_fq_factor, noise_level )
% Creates an artificial LFP signal so that we can test different signal
% detection algorithms. Gain modulation allows you to create an artificial
% signal that maintains a given frequency but in which the gain slowly
% changes.
%
% INPUT: sFreq = sampling frequency of the data 
%        duration_sec = how long of a sample to produce (in seconds)
%        frequencies = (vector) frequencies to embed in the LFP
%        gain_modulation_fq_factor = 2 rows with length(frequencies) columns
%        noise_level = how much noise to add.
% OUTPUT: (none) - generate a plot
%         L = signal
%         INFO = stuff.
%
% Cowen (2012)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin == 0
    sFreq = 1000;
    duration_sec = 20;
    frequencies = [8 ];
    gain_modulation_fq_factor = [0.5  ; .1  ]; % should be divisible into the associated value in Frequencies.
    %gain_modulation_fq_factor = [0  ; 0  ];
    noise_level = 0.1;
end
%%
npts = ceil(duration_sec*sFreq);
L = zeros(1,npts);
INFO.T = linspace(0, duration_sec, npts );

for iF = 1:length(frequencies)
    n_cycles = frequencies(iF)*duration_sec;
    x = linspace(0,n_cycles*2*pi,npts);
    s = sin(x);
   
    if gain_modulation_fq_factor(1,iF) ~= 0
       
        n_cycles_gm = gain_modulation_fq_factor(1,iF)*duration_sec;
        x_gm = linspace(0,n_cycles_gm*2*pi,npts);
        s_gm = sin(x_gm) + 2; % Slowly changing gain multiplier of this frequency. IS THIS CORRECT?
        
        L = L + (s .* s_gm .*  gain_modulation_fq_factor(2,iF)); % the gain modulation.
    else
        L = L + s;
    end
    
end

if noise_level ~= 0
    L = L + randn(1, npts) * noise_level;
end
%%
if nargout == 0
    figure
    subplot(3,1,1)
    
    [S,F,T,P] = spectrogram(L,128,[],[0.05:.5:50],sFreq);
    P_log = 10*log10(abs(P));
    %imagesc(T,F,P_log) % From help on spectrogram, but visualy it looks better without the log. Interesting. Plus, the log makes everything negative which is harder to work with.
    imagesc(T,F,abs(P)) % From help on spectrogram, but visualy it looks better without the log. Interesting. Plus, the log makes everything negative which is harder to work with.

    F_range_IX = F > 4 & F < 12; % Restrict to theta range.
    restricted_P = sum(P(F_range_IX,:),1)';
    hold on
    plot(T,zscore(restricted_P)+10,'g')
    plot(INFO.T, zscore(L')+20,'w')

    subplot(3,1,2)
    plot(INFO.T,zscore(L'))
    hold on
    plot(T,zscore(restricted_P'),'r')
    
    subplot(3,1,3)
    
    
    
    
    win_size_sec = .200; % size of the sliding window
    win_size = round(sFreq*win_size_sec);
    [F,xF] = pwelch(L',win_size,[],sFreq,sFreq);
    plot(xF,F)
    xlabel('Fq (Hz)')
%%%%%%    
    figure
    psFreq = 1/mean(diff(T));
    subplot(2,2,1)
    pmtm(restricted_P,[],[],psFreq)
    
    subplot(2,2,2)
    win_size_sec = 8.0; % size of the sliding window
    win_size = round(psFreq*win_size_sec);
    [F,xF] = pwelch(restricted_P,win_size,[],[],psFreq);
    plot(xF,F)
    xlabel('Fq (Hz)')
     
    subplot(2,2,3)
    pmtm(L,3,0.5:.2:20,sFreq) % Sucks - chronux is nice.
    
    subplot(2,2,4)

    win_size_sec = .200; % size of the sliding window
    win_size_idx = round(sFreq*win_size_sec);
    psd_window = round(win_size_idx);
    [F,xF] = pwelch(L',psd_window,[],sFreq,sFreq);
    plot(xF,F)
    xlabel('Fq (Hz)')

    figure
    subplot(1,3,1:2)
    [S2,F2,T2,P2] = spectrogram(restricted_P,64,[],[0.01:.02:8],psFreq);
        
    imagesc(T2,F2,abs(P2)) 
    subplot(1,3,3)
    plot_confidence_intervals(F2,abs(P2)')
    
    
end
