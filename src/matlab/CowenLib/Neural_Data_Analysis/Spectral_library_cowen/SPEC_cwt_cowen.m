function [pow,fqs,scales]=SPEC_cwt_cowen(LFP, sFreq, fq_range, varargin)
% function [pow,fqs,scales]=SPEC_cwt_cowen(LFP, sFreq, fq_range, varargin)
% Wavelet transform of LFP data. 
% INPUT: LFP signal
%        sFreq of the signal
%        fq_range = range of frequencies OR specific frequencies to extract. 
%   OPTIONAL     
%         wname (e.g., 'wname', 'bump') allows you to specify the wavelet
%            family. The default is Morelet.
%  resolution per octave - cwt works in octaves and then post-hoc
%          converst to specific frequencies that you might have specified. Be
%          sure to provide enough resolution to allow interpolation of the
%          frequencies that you want. 16 or 32 are common choices.
%         plot_it- plot results.
%
% OUTPUT: pow - power and phase as complex double.
%             fqs - the frequencies extracted.
%             scalse - wavelet scales
%
% Requires Matlab wavelet toolbox
% ISSUES: How do you get phase from this? Is it just angle?
%
% Cowen 2022
plot_it = false;
if nargout == 0
    plot_it = true;
end
wname = 'morl'; % morelet.
%  wname = 'bump'; % bump wavelet family.
padding = 'zpd'; % use this as the default creates strange results.
% padding = 'sym'; % This creates strange results - odd frequency
% responses. It's the default so look out.
fq_smoother = 'linear'; % nearest is nother option
resolution_per_octave = 32;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Extract_varargin;

if strcmpi(wname,'bump')
    f0 = centfrq('morl'); % use this as an estimate as centfrq does not work with bump wavelets.
else
    f0 = centfrq(wname);
end

if nargin < 5
    plot_it = false;
end

if nargin == 0
    sFreq = 1000;
    fq_range = [.5 sFreq/2];
    resolution_per_octave = 32;
    duration_sec = 2;
    noise = 0;
    tgt_Hz = [150];
    [LFP] = Artificial_LFP(sFreq, duration_sec, tgt_Hz, 0, noise );
    
    interval_s = 1/sFreq;
    t = 0:interval_s:duration_sec;
    fo = 30; f1 = 300;     % Frequency - linear increase from f0 to f1
    LFP = chirp(t,fo,t(end),f1);
    fq_range = [2 500];
    %     scale_inc = 0.1;
    
    figure
    [pow1,fqs,scales] = SPEC_cwt_cowen(single(LFP),sFreq,fq_range,'resolution_per_octave', resolution_per_octave,'plot_it',false);
    surf(t,fqs,abs(pow1).^2,'edgecolor','none');
    view(0,90);
    % Compare this with SPEC_Waveformdecomposition.
    figure
    [ph,pow2]=SPEC_waveletdecomp(fqs,LFP,sFreq,6,false,false);
    surf(t,fqs,pow2,'edgecolor','none');
    view(0,90);
    % Compare with spectrogram.
    figure
    spectrogram(LFP,blackman(128),120,linspace(fqs(1),fqs(end),200),sFreq)
    
    figure
    subplot(2,1,1)
    imagesc(abs(pow1))
    subplot(2,1,2)
    imagesc(pow2)
    drawnow
    % benchmark
    [LFP] = Artificial_LFP(sFreq, 10*60, tgt_Hz, 0, noise );
    LFP = single(LFP);
    tic
    [pow1,fqs,scales] = SPEC_cwt_cowen(LFP,sFreq,fq_range,'resolution_per_octave', resolution_per_octave,'plot_it',false);
    wv = toc
    tic
    [ph,pow2]=SPEC_waveletdecomp(fqs,LFP,sFreq,6,false,false);
    wv2 =  toc

    return
    
end
if isempty(fq_range)
    fq_range = [.5 sFreq/2];
end
% This is a kludge to account for SPEC_helperCWTTimeFreqVector cutting off
% the lower bound of the frequencies.
min_freq = min(fq_range) - 10;
if min_freq < .5
    min_freq = .5;
end
scales = SPEC_helperCWTTimeFreqVector(min_freq,max(fq_range),f0,1/sFreq,resolution_per_octave);
CW = cwtft({LFP,1/sFreq},'wavelet',wname,'scales',scales,'padmode',padding);
% [coefs,sgram,frequencies] = cwt(LFP,scales,'morl',1/sFreq,'scalCNT');
pow = CW.cfs;
fqs = CW.frequencies(:);
% make the ordering of frequencies sane - ascending. Default is descending
fqs = fqs(end:-1:1);
pow = pow(end:-1:1,:);
% Restrict to the passed-in fq range
if ~isempty(fq_range)
    GIX = fqs >= min(fq_range) & fqs <= max(fq_range);
    fqs = fqs(GIX);
    pow = pow(GIX,:);
end

if length(fq_range)>2
    % If the user wanted specific frequencies, then we will just have to
    % interpolate...
    pow = interp1_matrix(fqs, pow, fq_range(:), fq_smoother); % nearest?
    fqs = fq_range;
end
%% make the ordering of frequencies sane - ascending. Default is descending
% fqs = fqs(end:-1:1);
% pow = pow(end:-1:1,:);

if plot_it
    t_sec = (1:length(LFP))/sFreq;
    %     surf(t_sec,frequencies,abs(coefs).^2,'edgecolor','none');    view(0,90);

    SPEC_helperCWTTimeFreqPlot(CW.cfs,t_sec,CW.frequencies,...
        'surf','CWT','Seconds','Hz');
    %     hold on
    %     cone = conofinf(wname,scales,length(LFP),1,'plot'); % how do we plot
    %     this ontop?
end
% cone = conofinf(wname,scales,length(LFP),1,'plot');
%
%
% sig = struct('val',LFP,'period',1/LFP_sFreq);
% cwtS1 = cwtft(sig);
% cwtS1 = cwtft(sig,'plot');
