function [phase, pk_ix, tr_ix, assym, updown_ix] = ...
    Phase_pow_fq_detector_waveshape(wideLFP,narrowLFP,sFreq)
% function [phase, pk_ix, tr_ix, assym, updown_ix] = ...
%     Phase_pow_fq_detector_waveshape(wideLFP,narrowLFP,sFreq)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make narrowLFP not too narrow. perhaps 20% wider than your typical range
% for the frequency. WideLFP - get rid of slow changes in mean - perhaps
% medfilt before sending it in.
%
% NOTE: Upsample this if you want better time/phase resolution.
%
% Make wide not complete wide band. Perhaps 200% wider than the target
% frequency.
%
% SEE BULLSCIO BUZSAKI PAPER
% Belluscio, M. A., Mizuseki, K., Schmidt, R., Kempter, R., & Buzsáki, G. (2012). Cross-frequency phase-phase coupling between ? and ? oscillations in the hippocampus. The Journal of Neuroscience : The Official Journal of the Society for Neuroscience, 32(2), 423–435. https://doi.org/10.1523/JNEUROSCI.4122-11.2012
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2020 - updated to uncorporate zero crossings.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin ==0
    % Validate with some real data...
    tst = load('I:\waveformstuff.mat');
    figure
    plot(tst.LFPep(:,1),tst.LFPep(:,2))
    hold on
    plot(tst.narrow(:,1),tst.narrow(:,2))
    plot(tst.broad(:,1),tst.broad(:,2))
    sFreq = 1e6/median(diff(tst.broad(:,1)));
    wideLFP = tst.broad(:,2);
    narrowLFP = tst.narrow(:,2);
end

assym = []; inst_fq2 = [];
if nargin < 3
    sFreq = 1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[~,~,zup_ix,zdown_ix] = Find_peaks_troughs_zeros(narrowLFP);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

new_zdown_ix = zeros(size(zup_ix));
for ii = 1:length(zup_ix)-1
    tmp = find(zdown_ix > zup_ix(ii),1,'first');
    if isempty(tmp)
        break
    else
        new_zdown_ix(ii) = zdown_ix(tmp);
    end
end
zup_ix = zup_ix(1:(ii-1));
zdown_ix = new_zdown_ix(1:(ii-1));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% always start with the peak - the rise up, end with a trough. Keeps things consistent.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if zup_ix(1) > zdown_ix(1)
    zdown_ix(1) = [];
end
if zup_ix(end) > zdown_ix(end)
    zup_ix(end) = [];
end
updown_ix = sort([zup_ix;zdown_ix]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now deal with the WIDE filtered data. Find peaks and troughs...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find the zero crossings for the wide data...
[~,~,zup_ix_wide,zdown_ix_wide] = Find_peaks_troughs_zeros(wideLFP);
% find the closes zup_ix_wide for each zup_ix...
tmp = ones(length(zup_ix),1);
for ii = 1:length(zup_ix)
    ix = binsearch(zup_ix_wide,zup_ix(ii));
    tmp(ii) = zup_ix_wide(ix);
end
zup_wide_ix = tmp;

tmp = ones(length(zdown_ix),1);
for ii = 1:length(zdown_ix)
    ix = binsearch(zdown_ix_wide,zdown_ix(ii));
    tmp(ii) = zdown_ix_wide(ix);
end
zdown_ix_wide = tmp;

updown_wide_ix = sort([zup_wide_ix;zdown_ix_wide]);

cnt = 1;
pk_ix = nan(round(length(updown_ix)/2),1);
tr_ix = nan(round(length(updown_ix)/2),1);
for ii = 1:2:length(updown_ix)-2
    [~, m] = max(wideLFP(updown_ix(ii):updown_ix(ii+1)));
    pk_ix(cnt) = m + updown_ix(ii) - 1;
    [~, m] = min(wideLFP(updown_ix(ii+1):updown_ix(ii+2)));
    tr_ix(cnt) = m + updown_ix(ii+1) - 1;
    cnt = cnt + 1;
end
tr_ix = tr_ix(1:(cnt-1));
pk_ix = pk_ix(1:(cnt-1));
fall = (tr_ix - pk_ix);
rise = (pk_ix(2:end) - tr_ix(1:end-1));
rise = [rise(1); rise];
% get rid of strange situations where the the peak and trough are the same
% value. 
BIX = fall <= 0 | rise <=0;
pk_ix = pk_ix(~BIX);
tr_ix = tr_ix(~BIX);
fall = (tr_ix - pk_ix);
rise = (pk_ix(2:end) - tr_ix(1:end-1));
rise = [rise(1); rise];

assym = [pk_ix (fall)./(rise + fall) - .5] ;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Problems - at every 90 degrees.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
phase_old = nan(size(wideLFP));
phase = nan(size(wideLFP));
for ii = 1:length(pk_ix)
    % find the zero crossing after the peak.
    zcix = find(zdown_ix_wide>pk_ix(ii),1,'first');
    zc = zdown_ix_wide(zcix);
    if zc == tr_ix(ii)
        zc = tr_ix(ii) - round((tr_ix(ii) - pk_ix(ii))/2);
    end
    
    ix = pk_ix(ii):tr_ix(ii);
    phase(ix) = interp1([pk_ix(ii) zc tr_ix(ii)],[0 pi/2 pi],ix(:),'linear');
    
    phase_old(ix) = linspace(0,pi,length(ix));
end
for ii = 1:length(tr_ix)-1
    zcix = find(zup_ix_wide>tr_ix(ii),1,'first');
    zc = zup_ix_wide(zcix);
    if zc == pk_ix(ii+1)
        zc = pk_ix(ii+1) - round((pk_ix(ii+1) - tr_ix(ii))/2);
    end
    
    ix = tr_ix(ii):pk_ix(ii+1);
    
    phase(ix) = interp1([tr_ix(ii) zc pk_ix(ii+1)],[pi 1.5*pi 2*pi],ix,'linear');
        
    phase_old(ix) = linspace(pi,2*pi,length(ix));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if 0
    figure 
    % NOTE: THe clustering around 0, 180 degrees makes sense as we are
    % using linspace to assign phase which GUARANTEES that you will have a
    % point at 0 180 for EVERY cycle. The other phases will be less
    % represented because linspace will assign different phases depending
    % on the number of points. Could up the sampling rate and this would
    % reduce the problem a little.
    histogram(phase,700)
    
    figure
    histogram(assym(:,2),70)
    
    %
    figure
    plot(wideLFP,'k')
    hold on
    plot(wideLFP,'k.')

    plot(narrowLFP,'b')
    plot(updown_ix(1:2:end),narrowLFP(updown_ix(1:2:end)),'ro')
    plot(updown_ix(2:2:end),narrowLFP(updown_ix(2:2:end)),'b*')
    plot(updown_wide_ix(1:2:end),wideLFP(updown_wide_ix(1:2:end)),'mp')
    plot(updown_wide_ix(2:2:end),wideLFP(updown_wide_ix(2:2:end)),'m+')
    plot_horiz_line_at_zero()

    plot(tr_ix,wideLFP(tr_ix),'m^')
    plot(pk_ix,wideLFP(pk_ix),'g^')
    set(gca,'Ylim',prctile(wideLFP(1:40:end),[.1 99.9]))
    
    plot(rad2deg(phase),'r-')
    hold on
    plot(rad2deg(phase_old),'b-')
    %
end
