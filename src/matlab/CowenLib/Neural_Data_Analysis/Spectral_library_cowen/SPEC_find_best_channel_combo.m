function [INFO] = SPEC_find_best_channel_combo(LFP,target_band_filt,control_band_filt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT: LFP = nsamp x nch matrix
%        target band filt - filt from bandpasfilt band with oscillation you want.
%        control_band - from bandpass filt band to subtract from target as the sign-to-noise
%        measure.
%
% Go through each channel pair and compare. 

nCh = Cols(LFP);
Pt = zeros(1,Cols(LFP));
Pc = zeros(1,Cols(LFP));
for iCh = 1:Cols(LFP)
    f = filtfilt(target_band_filt,LFP(:,iCh));
    Pt(iCh) = rms(f);
    f = filtfilt(control_band_filt,LFP(:,iCh));
    Pc(iCh) = rms(f);
end
INFO.ratings_non_reref = Pt-Pc;
INFO.ratings_non_reref_prop = (Pt-Pc)./(Pt+Pc);

INFO.ratings_non_reref_ratio = Pt./Pc;

SC = nan(nCh);
for iCh1 = 1:nCh
    for iCh2 = iCh1+1:nCh
        RR = LFP(:,iCh1) - LFP(:,iCh2);
        f = filtfilt(target_band_filt,RR);
        PPt = rms(f);
        f = filtfilt(control_band_filt,RR);
        PPc = rms(f);
        SC(iCh1,iCh2) = PPt-PPc;
    end
end
INFO.scores_by_combo = SC;
[~,INFO.best_non_reref] = max(INFO.ratings_non_reref);
[~,INFO.best_non_reref_ratio] = max(INFO.ratings_non_reref_ratio);
[~,INFO.best_non_reref_prop] = max(INFO.ratings_non_reref_prop);


INFO.best_reref_combo = nan;
[~,INFO.best_reref_combo(1)] = max(max(SC,[],1));
[~,INFO.best_reref_combo(2)] = max(max(SC,[],2));


if nargout == 0
    subplot(1,2,1)
    bar(INFO.ratings_non_reref)
    subplot(1,2,2)
    imagesc(SC)
end
