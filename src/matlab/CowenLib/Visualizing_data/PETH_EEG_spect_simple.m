function [PSDs, fq, M, ix, xtimes] = PETH_EEG_spect_simple(EEG_t_data, alignments_t, samples_before, samples_after, sFreq, fq_range)
%% A far simpler version than my PETH_EEG program - which is very hard to
%% debug but does a lot of extra things.
%
% INPUT: EEG_t_data = 2 col matrix - first col is time, second is the data.
%        alignments_t = the timestamps of the times to be aligned.
%        samples_before = samples before to capture on each event.
%        samples_after  = samples after to capture on each event.
%        sFreq (optional) - for plotting only.
%
% events outside the range are turned into Nans.
%
% cowen 2012
if nargin < 6
    fq_range = [1;1]; %changed this so that the range is 1 so that you can omit 6th arg. -DHill 11-3-2016
end
buffer_size_samples = 500; % This is my choice- it's somewhat arbitrary and assumes that you are not really sampling faster than 2khz

if ~isa(EEG_t_data,'double') || ~isa(EEG_t_data,'single')
    EEG_t_data = double(EEG_t_data);
end

if 0
    % used these data to validate.
    samples_before = 4;
    samples_after = 6;
    
    EEG_t_data = [1:1000; rand(1,1000)]';
    EEG_t_data(1:20:1000,2) = 1;
    alignments_t = 1:20:1000;
end
%
% tic
% eeg_samples = binsearch_vector(EEG_t_data(:,1),alignments_t); % only accepts doubles.
% toc
% tic
% eeg_samples = Closest(EEG_t_data(:,1),alignments_t); % only accepts doubles.
% toc

eeg_samples = int32(round(interp1(EEG_t_data(:,1)',1:Rows(EEG_t_data),alignments_t)));

ix = (-1*samples_before-buffer_size_samples):1:(samples_after + buffer_size_samples);
Mix = repmat(int32(ix),length(eeg_samples),1);
for ii =1:length(eeg_samples)
    Mix(ii,:) = Mix(ii,:) + eeg_samples(ii);
end
BADIX = Mix>Rows(EEG_t_data) | Mix<1;
Mix(BADIX) = 1;
%

M = EEG_t_data(reshape(Mix,Rows(Mix)*Cols(Mix),1),2);
M = reshape(M, Rows(Mix), Cols(Mix));
M(BADIX) = nan; % records outside of the range.

% Perform the spectrogram
rng = samples_before + samples_after;
dd = sFreq/fq_range(1);
window = max([dd*.5, 64, round(rng/5)]);
noverlap = round(window*.5); nfft = 256; % oringina  Change noverlap to increase speed or decrease resolution.
%window = 128; noverlap = 120; nfft = 256; % oringina  Change noverlap to increase speed or decrease resolution.
[~, fq, times,P] = spectrogram(M(1,:),window,noverlap,nfft,sFreq);
BADfqIX = fq<fq_range(1) | fq > fq_range(2);
fq(BADfqIX) = [];

%[tfr,T,F]=tfrwv(M(1,:)', 1:Cols(M)',40); % Time frequency toolbox function.
%^ imagesc(t/sFreq,F,flipud(tfr));
PSDs = NaN(numel(fq),size(P,2),size(M,1),'single');
% Get the raw specrograms.
for rr = 1:size(M,1)
    [~, ~, times,tmp] = spectrogram(M(rr,:),window,noverlap,nfft,sFreq);
    tmp = real(tmp);
    PSDs(:,:,rr) = 10*log10(tmp(~BADfqIX,:));
%     PSDs(:,:,rr) = PSDs(:,:,rr));
end
% Clean off the buffer that we tacked onto the ends.
M = M(:,buffer_size_samples:(Cols(M)-buffer_size_samples));
ix = ix(buffer_size_samples:(length(ix)-buffer_size_samples));

xtimes = times - (samples_before+buffer_size_samples)/sFreq;
start_time_sec = -1*samples_before/sFreq;
end_time_sec = samples_after/sFreq;
good_IX = xtimes >= start_time_sec & xtimes <= end_time_sec;
PSDs = double(PSDs(:,good_IX,:));
xtimes = xtimes(good_IX);

if nargout == 0
    %M = standardize_range(M')';
    x = ix/sFreq;
    test_significance = false;
    
    mnPSDs = squeeze(nanmean(PSDs,3));
%     mnPSDs = standardize_range(mnPSDs')';
    
    if test_significance
        P = zeros(size(PSDs,1),size(PSDs,2));
        for ii = 1:size(PSDs,1)
            for jj = 1:size(PSDs,2)
                P(ii,jj) = signtest(squeeze(PSDs(ii,jj,:)));
            end
        end
    
        mnPSDs(P>0.05)= nan;
    end
    
    subplot(4,1,1:2)
    imagesc(xtimes,fq,mnPSDs)
    colormap(jet)
    colorbar_label('-1to1')
    
    axis xy
    ylabel('Hz')
    
    subplot(4,1,3)
    imagesc(x,[],M)
    colormap(jet)
    colorbar_label('')
    % Change the color scale.
    caxis_min = prctile(M(~isnan(M)),1);
    caxis_max = prctile(M(~isnan(M)),99);
    caxis([caxis_min caxis_max])
    ylabel('trial')
    
    subplot(4,1,4)
    plot_confidence_intervals(x,M)
    title('mean of raw LFP')
    xlabel('sec')
    axis tight
    box off
    subplot(4,1,1:2) % return the top axis handle to the user.
    
end


