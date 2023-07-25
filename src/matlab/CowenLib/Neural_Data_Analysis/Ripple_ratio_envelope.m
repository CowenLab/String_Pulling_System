function [RR,ENVFR,ENVFG,FR,FG] = Ripple_ratio_envelope(RIP_DATA,sFreq)
% THIS RATIO APPROACH WAS NOT WORKING - THIS APPROACH HAS BEEN ABANDONED
% BUT I STILL THINK IT HAS PROMISE. INSTEAD, I USED PMTM AND COMPUTED TEH
% RATIOS THIS WAY. MORE RELIABLE>
%
% We found that many false ripples were being detected. One thing we
% noticed is that many of these bad ripples could be identified if you
% looked at the high-gamma frequency preceding the ripple frequency - this
% was high relative to the ripple peak. 
% INPUT: LFP  - assumed equal spacing of samples.
%        sFreq
% OUTPUT: ration of power in ripple band to the power in the high-gamma
% band.
% 
% Cowen 2014
window_buffer = ceil(sFreq/50);
RIP_DATA = RIP_DATA(:);

lowlimit_fq = 140;
highlimit_fq = 260;

gamma_lowlimit_fq = 80;
gamma_highlimit_fq = 100;

% gamma_lowlimit_fq = 300;
% gamma_highlimit_fq = 400;


FR = Filter_200hz_simple(RIP_DATA, lowlimit_fq, highlimit_fq,sFreq);
FG = Filter_200hz_simple(RIP_DATA, gamma_lowlimit_fq, gamma_highlimit_fq,sFreq);

% ENV = conv_filter(ENV,hanning(5)/sum(hanning(5)));
%ENVFR = Z_scores(envelope(FR));
ENVFR = envelope(FR);

FG = conv_filter(FG,hanning(20)/sum(hanning(20)));
ENVFG = envelope(FG)*2;
% ENVFG = Z_scores(envelope(FG));


ENVFG(1:window_buffer) = nan;
ENVFG(end-window_buffer:end) = nan;

ENVFR(1:window_buffer) = nan;
ENVFR(end-window_buffer:end) = nan;

% RR = (ENVFR-ENVFG)./(ENVFR+ENVFG);
% RR = ENVFR-ENVFG;
RR = ENVFR./ENVFG;


if nargout == 0
    plot_LFP(standardize_range([RIP_DATA FR FG ENVFR ENVFG RR]));
end
