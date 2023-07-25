function O = Interpolate_through_FSCV_scans(t_ms,scnt_ms,scan_blank_duration_ms)
% function O = Interpolate_through_FSCV_scans(t_ms,scnt_ms,scan_blank_duration_ms)
%
% Approach: Binning in equal bins of the same size as the scan pulse.
% Then find the bins that overlap with a scan (1 or 2 max). Pull those bins out of the original data and
% then interpolate using the redacted data to find the pulled out times.
% UPSHOT: It works, mostly. It's much cleaner than not interpolating, but
% if you smooth a lot, you still see the scan times. I still think it will
% significantly 'clean' the PETHs anyway.
%
% For the DANA project but may be good for other projects that need to
% interp through periodic artifacts.
%
% OUTPUT: Spike times binned at a bin size of the scan interval and bin
% center timestamps.
%
% NOTE: if you want a different bin size, just interpolate the output from this function - or resample at a
% different rate or interval. You can also smooth these data. I'll leave
% this to you, but do not change the scan_blank_duration_ms beyond the true
% blanked out scan interval.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2019
if scan_blank_duration_ms > 20
    disp('WARNING: Your scan duration seems FAR TOO LONG. Should be around 10-14 ms.')
end

bin_size_ms = scan_blank_duration_ms; % should be about the same size as the scan pulse blank out interval. Looking at the data, 13.167 seems to be the correct amount but 14 is close enough..

desired_t_ms = t_ms(1):bin_size_ms:t_ms(end);

% Bin the data first.
[B,setimes] = Bin_ts_array(t_ms,bin_size_ms);
Borig = B;
ctrs = mean(setimes,2);
bix = [];
% Find the bins that overlap with the scan times and pull them out (bad
% bins)
sv = scnt_ms(:);
for iScan = 1:length(sv)
    ix = find(setimes(:,1) <= sv(iScan),1,'last');
    bix = [bix; ix];
end
for iScan = 1:length(sv)
    ix = find(setimes(:,1) >= sv(iScan),1,'first');
    bix = [bix; ix];
end

bix = unique(bix);
gix = setdiff(1:length(B), bix);
% Fill the missing times with the best guess - which is a linear estimate
% based on the preceding good bin and the following good bin.
B(bix) = interp1(ctrs(gix), B(gix), ctrs(bix), 'linear');
% Return output to user.
O = [desired_t_ms(:) B(:)];

if nargout == 0
    % Plots for double checking.
    figure
    plot(B)
    hold on
    plot(convn(B,hanning(10),'same'))
    
    figure
    PETH_EEG_simple([ctrs(:) B(:)],scnt_ms(:,1),300/bin_size_ms,300/bin_size_ms, 1000/bin_size_ms,1)
    colorbar_label
    
    % original - should show nasty artifacts.
    figure
    PETH_EEG_simple([ctrs(:) Borig(:)],scnt_ms(:,1),300/bin_size_ms,300/bin_size_ms, 1000/bin_size_ms,1)
    colorbar_label
    
    % With a hellufa lot of smoothing.
    figure
    PETH_EEG_simple([ctrs(:) convn(B,hanning(10),'same')],scnt_ms(:,1),300/bin_size_ms,300/bin_size_ms, 1000/bin_size_ms,1)
    colorbar_label
end