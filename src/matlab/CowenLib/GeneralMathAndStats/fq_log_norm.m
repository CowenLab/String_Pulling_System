function M = fq_log_norm(EEG,fq)
% Do a frequency normalization for better visualazation of the power
% spectrogram of eeg data.
% CONVERTS TO REAL.
if nargin < 2
    fq = 1:Cols(EEG);
end
M = real(log(EEG.* repmat(fq(:)',Rows(EEG),1)));