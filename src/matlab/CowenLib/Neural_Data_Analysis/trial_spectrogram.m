function [SPEC,fq,times,P,S] = trial_spectrogram(M,Fs,window,nfft,noverlap)
if nargin < 3
    window = 32;nfft = 256; noverlap = 8;
end
[tSPEC, fq, times,P] = spectrogram(M(1,:),window,noverlap,nfft,Fs);
SPEC = zeros(length(fq),length(times),Rows(M))*nan;
S = zeros(length(fq),length(times),Rows(M))*nan;
SPEC(:,:,1) = P;
S(:,:,1) = tSPEC;
for ii = 2:Rows(M)
    [S(:,:,ii), fq, times,SPEC(:,:,ii)] = spectrogram(M(ii,:),window,noverlap,nfft,Fs);
end