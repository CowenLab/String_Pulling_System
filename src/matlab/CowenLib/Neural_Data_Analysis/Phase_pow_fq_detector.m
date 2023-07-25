function [phase_hilbert, pow_hilbert, inst_fq, pk_ix, tr_ix, assym, inst_fq2 ] = ...
    Phase_pow_fq_detector(V,sFreq)
% function [phase_hilbert, pow_hilbert, inst_fq, pk_ix, tr_ix, inst_fq2 ] = Phase_pow_fq_detector(V,sFreq)
% Detect the instantaneous phase, power, and frequency of a signal
% (prefereably highly filtered).
%
% TO DO: Make a 'sister' function that does the same thing but based on the
% waveform shape (the only moderately filtered signal and then
% interpolating from peak to zero cross to trough (180 back to zero cross
% and peak). Similar to my old Find Peaks trough phase code. Assymetry will
% be better with this since it will be based on a wide-band filtered
% signal...
% 
% Cowen 2018
assym = []; inst_fq2 = []; pk_ix = []; tr_ix = [];
if nargin < 2
    sFreq = 1;
end

H = hilbert(-1*V); % we need to invert so that the peak is 0 or 360;
phase_hilbert = angle(H)+pi; % we need to add pi so that the range is from 0 to 360 and not -180 to 180;
pow_hilbert = abs(H);
if 0
    % this is the hilbert way. instfreq defaults to another way which seems
    % less noisy and more robust
    instfreq_H = sFreq/(2*pi)*diff(unwrap(angle(H)));
    instfreq_H = movmedian(instfreq_H,50);
    instfreq_H = movmean(instfreq_H,sFreq*2);
end
% new school inst freq estimation.
[ifq,t] = instfreq(V,sFreq); % also see https://www.mathworks.com/help/signal/ug/hilbert-transform-and-instantaneous-frequency.html
tix = round(t * sFreq); % convert time to indices.
% bookend these data. this avoids issue of not having vals for interp1 so
% that interp1 does not return nans - which sucks
ifq = [ifq(1); ifq; ifq(end)];
tix = [1;tix;length(V)];
inst_fq = interp1(tix,ifq,1:length(V));
%
if nargout > 3
    [pk_ix,tr_ix] = Find_peaks_troughs_zeros(V);
    %     for consistency, make it start with a peak and end with a trough.
    if pk_ix(1) > tr_ix(1)
        tr_ix(1) = [];
    end
    if pk_ix(end) > tr_ix(end)
        pk_ix(end) = [];
    end
end
% min_ix = min([length(pk_ix) length(tr_ix)]);
% fall = tr_ix(1:min_ix) - pk_ix(1:min_ix);
% rise = pk_ix(2:min_ix) - tr_ix(1:min_ix-1);
if nargout > 5
    
    % manually calc instantaneous frequency. old way. more noisy but it makes
    % sense. just look at intervals.
    % Find all peaks < 0 and remove. Find all troughs>0 and remove.
    % go through and only choose the peak that is the max of a
    % contiguous blokc and the trough that is the min of a contiguous
    % block.
    PT = [pk_ix(:) pi*ones(length(pk_ix),1);
        tr_ix(:) -pi*ones(length(tr_ix),1)];
    PT = sortrows(PT,1);
    intervals = [nan; diff(PT(:,1))]; %
    intervals(intervals == 1) = nan;
    % Assymetry is the ratio of the time from tr to peak to the subsequent pk to tr.
    first_ix = find(PT(:,1)==pk_ix(1),1, 'first');
    last_ix = find(PT(:,1)==tr_ix(end),1, 'last');
%     x_ix = PT(first_ix:end,1);
    x_ix = PT(first_ix:last_ix,1);
    d = diff(x_ix)/sFreq;
    rise = d(1:2:end-1);
    fall = d(2:2:end);
%     new_pk_ix = pk_ix(pk_ix > tr_ix(1) & pk_ix < tr_ix(end));
    assym_tmp = fall./(rise+fall) - .5;
    assym = [pk_ix(1:end-1) assym_tmp(:)];
    
    intervals_sec = 2*intervals/sFreq; % mult by 2 because get trough .
    intervals_sec = movmedian(intervals_sec,5); % get rid of wacko outliers.
    intervals_sec = movmean(intervals_sec,5); % smooth a little.
    % do it old school - just intevals between peaks.
    ifq1 = 1./intervals_sec;
    ifq1 = [ifq1(1); ifq1; ifq1(end)];
    T = [1;PT(:,1);length(V)];
    ix = find(~isnan(ifq1),1,'first');
    ifq1(1:ix-1) = ifq1(ix);
    GIX = ~isnan(ifq1);
    inst_fq2 = interp1(T(GIX),ifq1(GIX),1:length(V));
end
%

if 0
    figure
    ix =1:20000;
    plot(ix,V(ix),ix,phase_pk_tr(ix),ix,pow_pk_tr(ix))
    hold on
    plot_markers_simple(pk_ix(pk_ix < ix(end)),[],[],'r')
    plot_markers_simple(tr_ix(pk_ix < ix(end)),[],[],'g')
    legend('theta','ph','pow')
    
    figure
    plot(ix,V(ix),ix,pow_pk_tr(ix),ix,pow_hilbert(ix))
    legend('theta','powpktr','powhil')
    
    %     phase_pk_tr(isnan(phase_pk_tr)) = 0;
    figure
    plot(ix,phase_pk_tr(ix))
    
    hold on
    %     plot(ix,phase_pk_tr(ix)))
    plot(ix,phase_hilbert(ix))
end
