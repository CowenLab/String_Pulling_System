function  [SE_times_above_usec SE_times_below_usec thresh_uVoltsSquared PT smooth_eeg] = ...
    ripple_times(EEG, threshold, plot_it)
%function  [SE_times_above_usec SE_times_below_usec thresh_uVoltsSquared smooth_eeg] = ...
%    ripple_times(EEG, threshold, plotit)
%
% INPUT: 
% 
%      EEG  = the .NCS filename of the eeg file 
%           OR a 2 column matrix where the 1st column is time (in uSec!), 
%           the second col is the eeg data filtered in the 200hz range
%           (e.g. [100 300])
%
%      threshold = The method for determining the threshold for determining
%                  the start and end of a ripple.
%                  - if a scalar value is provided, then this is the value in 
%                    uVolts (or whatever the units are that you pass in)  
%                    that will determine the threshold for detection. This
%                    value can be estimated by comparing the output of this
%                    function (smooth_eeg) with the filtered input data.
%                    Just plot these data on top of each other and it will
%                    give you a good guess regarding the threshold.
%                  - if a column vector of data is provided, it is assumed
%                    that this data is reference 'waking' data that will be
%                    used to determine the threshold automatically.
%                  - if a nan or nothing is provided, then the threshold is 
%                    set as 7SD above the mean.
%
%      plotit = if this parameter is set to 1, the times when eeg
%               exceeded threshold and start and end times and eeg
%               will be plotted using View_EEG.
%
% OUTPUT:
%
%     SE_times_above_usec = matrix of ripple start and end times
%     SE_times_below_usec = matrix of inter-ripple periods
%     thresh_uVolts = The determined threshold
%     smooth_eeg = the smoothed version of the data used for thresholding.
%     PT = a structure with the times of the peaks and troughs within each interval
%
% cowen (2006)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargout == 0
    plot_it = 1;
end
if nargin < 2
    threshold = [];
end
if nargin < 3
    plot_it = 0;
end

PT = [];


if isstr(EEG)
    % Assume it is a .Ncs file.
    fname = EEG;
    [T, EEG] = Read_CR_files(fname, 800, [], {'bandpass'}, {[100 300]});%, {'highpass'}, {20});
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Eliminate any DC offset. - shouldn't be any.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %EEG = EEG - nanmean(EEG);
    [SE_times_above_usec SE_times_below_usec thresh_uVolts smooth_eeg] = Ripple_times([T EEG], threshold, plotit);
    return
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
min_rip_duration_msec = 30; % If ripples aren't this long, delete them.
merge_threshold_msec  = 1;  % If 2 ripples are this close, merge them.
n_std_for_threshold   = 6; % number of std for threshold.
smooth_win_sec = 0.02;
sFreq = 1e6/nanmedian(diff(EEG(:,1)));
% down_sFreq = 100;
% Smoooooooth
smooth_win_pts = sFreq*smooth_win_sec;
hammwin = hamming(smooth_win_pts);
% ABS works well as well but perhaps not as strong of a sig to noise ratio.
%hammwin = hammwin/sum(hammwin);
%smooth_eeg = convn(abs(EEG(:,2)),hammwin,'same');
smooth_eeg = convn(EEG(:,2).^2,hammwin,'same');
smooth_ctrl_eeg = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine the threshold
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(threshold) | isnan(threshold)
    min_smooth = min(smooth_eeg);
    % Convert to something close to uVolts.
    %smooth_eeg = sqrt(smooth_eeg - min_smooth);
    threshold = mean(smooth_eeg) + n_std_for_threshold*std(smooth_eeg);
elseif length(threshold) > 2
    % Not implemented yet - waiting for drew. Also need to verify that
    % behaivor is clean.
    %  threshold = threshold - nanmean(threshold);
    smooth_ctrl_eeg = convn(threshold.^2,hammwin,'same');
    % Norm by the same scale as in the smooth EEG.
    %  smooth_ctrl_eeg = sqrt(smooth_ctrl_eeg - min_smooth);
    [h,r]   = ksdensity(log(smooth_eeg(1:6:end)),'npoints',300);
    [hb,rb] = ksdensity(log(smooth_ctrl_eeg(1:6:end)),'npoints',300);
%    nx = sort([r(:);rb(:)]);
    nx = linspace(min([r(:);rb(:)]),max([r(:);rb(:)]),400);
    nh = interp1(r,h,nx);
    nhb = interp1(rb,hb,nx);
    nh(isnan(nh)) = 0; nhb(isnan(nhb)) = 0;
    % [d,g] = group_data({log(smooth_ctrl_eeg(1:8:end)) log(smooth_eeg(1:8:end)) });
    % [TP_rate,FP_rate,STATS,TP_rate_rand,FP_rate_rand] = ROC(d, g, {'plot'}, {1});
    nh  = nh/sum(nh);
    nhb = nhb/sum(nhb);
    revx = nx(end:-1:1);
    revcs = cumsum(nh(end:-1:1)-nhb(end:-1:1));
    % plot(nx,nh,nx,nhb)
    % plot(revx,revcs)
    [mx,ix] = max(revcs);
    threshold = exp(revx(ix));
    % Another way to do this would be to take the difference between these
    % two functions and find the peak of the cumsum of this function
    % (starting at the right). The peak should approximate the maximal true
    % positives after subtracting false positives. See line_intersections
    % for this plot.
%    [x,y]   = line_intersections(nx,nh,nx,nhb);
%    [mx,ix] = max(h);
%    ix = find(x>median(log(smooth_ctrl_eeg)));
%    if isempty(ix)
%        disp('The distributions are strange. Using the 7SD rule')
%        threshold = mean(smooth_eeg) + n_std_for_threshold*std(smooth_eeg);
%    else
%        threshold = exp(x(ix(1)));
%    end
    % Find the peaks... (this really isn't necessary- could just use the
    % entire distribution of points)
    %    [PeaksIdxCtrl] = Find_peaks_troughs_zeros(smooth_ctrl_eeg);
    %    [PeaksIdx]     = Find_peaks_troughs_zeros(smooth_eeg);
    %    [h,r]   = ksdensity(log(smooth_eeg(PeaksIdx)),'npoints',300);
    %    [hb,rb] = ksdensity(log(smooth_ctrl_eeg(PeaksIdxCtrl)),'npoints',300);
    %    h = h/sum(h);
    %    hb = hb/sum(hb);
    %    [x,y]   = line_intersections(r,h,rb,hb);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DETERMINE THE INTERVALS: 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[SE_times_above_usec, SE_times_below_usec] = find_intervals([EEG(:,1) smooth_eeg(:)], threshold, nanmean(smooth_eeg)+nanstd(smooth_eeg),min_rip_duration_msec*1e3,merge_threshold_msec*1e3);

% Go out until the dirivative changes - good but start and end of ripple
% could have different amplitudes which seems wierd.
%[SE_times_above_usec, SE_times_below_usec] = find_intervals([EEG(:,1) smooth_eeg(:)],threshold, nan ,min_rip_duration_msec*1e3,merge_threshold_msec*1e3);
thresh_uVoltsSquared = threshold;
if nargout > 3
    disp('pk')
    tic
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Find the peak times within each interval.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [pkix trix] = Find_peaks_troughs_zeros(EEG(:,2));
    PeakTimes = EEG(pkix,1);
    TroughTimes = EEG(trix,1);
    PeakVals = EEG(pkix,2);
    TroughVals = EEG(trix,2);
    ix = Find_peaks_troughs_zeros(smooth_eeg);
    PeakTimesSmooth  = EEG(ix,1);
    PeakTimesSmoothVals  = smooth_eeg(ix);
    % Restrict these times to be within each interval.
    PT.Peaks = [];
    PT.Troughs = [];
    PT.SmoothPeak = zeros(Rows(SE_times_above_usec),2);
    pk_start_ix  = binsearch_vector(PeakTimes,SE_times_above_usec(:,1));
    pk_end_ix    = binsearch_vector(PeakTimes,SE_times_above_usec(:,2));
    tr_start_ix  = binsearch_vector(TroughTimes,SE_times_above_usec(:,1));
    tr_end_ix    = binsearch_vector(TroughTimes,SE_times_above_usec(:,2));
    spk_start_ix = binsearch_vector(PeakTimesSmooth,SE_times_above_usec(:,1));
    spk_end_ix   = binsearch_vector(PeakTimesSmooth,SE_times_above_usec(:,2));
    for iE = 1:Rows(SE_times_above_usec)
        ix = pk_start_ix(iE):pk_end_ix(iE)';
        PT.Peaks = [PT.Peaks; PeakTimes(ix) PeakVals(ix) ones(length(ix),1)*iE];
        ix = tr_start_ix(iE):tr_end_ix(iE)';
        PT.Troughs = [PT.Troughs; TroughTimes(ix) TroughVals(ix) ones(length(ix),1)*iE];
        ix = spk_start_ix(iE):spk_end_ix(iE)';
        t = PeakTimesSmooth(ix);
        e = PeakTimesSmoothVals(ix);
        [m,ix] = max(e,[],1);
        PT.SmoothPeak(iE,:) = [t(ix) m];
    end
    disp('epk')
    toc
    
end
%
if plot_it >0
    switch plot_it
        case 1
            subplot(2,1,1)
            plot(EEG(:,1),standardize_range(smooth_eeg,[0 max(EEG(:,2))]))
            hold on
            plot(EEG(:,1),EEG(:,2))
            %plot(EEG([1 end],1 ), threshold([1 1]),'r:')
            axis tight
            patch_intervals(SE_times_above_usec,'m',.2)
            %
            subplot(2,1,2)
            [h,r] = hist(log(smooth_eeg+eps),200);
            plot(r,h/sum(h))
            if length(smooth_ctrl_eeg) > 2
                [h,r] = hist(log(smooth_ctrl_eeg+eps),200);
                hold on
                plot(r,h/sum(h),'r')
                legend('rest','behavior')
            end
        case 2
            % plot a sample of the ripples with some context.
            nSamples = 10;
            nRip = Rows(SE_times_above_usec);
            r = randperm(nRip);
            samples = r(1:nSamples);
            samples = sort(samples);
            buffer_usec = 2e6;
            for iS = 1:nSamples
                    
                subplot(nSamples,1,iS);
                ix = find(EEG(:,1)> SE_times_above_usec(iS,1)-buffer_usec & EEG(:,1) < SE_times_above_usec(iS,2)+buffer_usec);
                
                plot(EEG(ix,1)/1e6,EEG(ix,2),'b')
                axis tight
                hold on
                ix2 = find(SE_times_above_usec(:,1) > (SE_times_above_usec(iS,1)-buffer_usec) & SE_times_above_usec(:,2) < (SE_times_above_usec(iS,2)+buffer_usec));
                patch_intervals(SE_times_above_usec(ix2,:)/1e6,'m',.2);
                set(gca,'FontSize',7)
                if iS==1
                    title('Random Sample of Ripples (200Hz filter)')                  
                end
            end
            xlabel('sec')
            ylabel('uV')
            orient tall
    end
end
