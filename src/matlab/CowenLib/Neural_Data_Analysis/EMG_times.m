function [SE_times_above_usec SE_times_below_usec thresh_uVolts TP] = ...
    EMG_times(EMG_file,epoch_times,thresh_uVolts);
% function [SE_times_above_usec SE_times_below_usec thresh_uVolts cemg] = ...
%     EMG_times(EMG_file,epoch_times,thresh_uVolts);
%
% determine periods of EMG in the data. - useful for sleep analysis.
%
%  INPUT:
%   EMG_file = filename of CSC emg file.
%   epoch_times = usec of start end times for epoch to analyze: TIMES ARE
%     ASSUMED TO BE IN USEC.
%   thresh_uVolts - voltage to consider as an emg burst. IF EMPTY, then
%   MANUALLY CHOOSE IT, IF NAN, Then set it to 1.1*the median of the
%   smoothed EEG trace.
%   smooth_size_sec = width of hanning in seconds used to smooth position
%     data. Default is 1 second.
%
% OUTPUT: 
%   the periods of EMG. usec
%   the periods of non-EMG within the specified epochs. usec
%   the threshold used for detection
%   the convolved position data used for detection.
% 
% if no outputs specified, it will plot out the position and smoothed
% EMG data.
% 
% cowen 2006
plot_it = 0;
if nargout == 0
    plot_it = 1;
end
if nargin < 3
    thresh_uVolts = [];
    plot_it = 1;
end
smooth_win_sec = 0.5;
sFreq = 2000;
down_sFreq = 20;
smooth_win_pts = down_sFreq*smooth_win_sec;
% load EMG
[T, EEG] = Read_CR_files(EMG_file, sFreq, epoch_times, {'bandpass'}, {[109 950]});%, {'highpass'}, {20});
% Generate a measure of movement by adding the movement at each point in the 
%  x dimension to the movement at each point in the y dimension.
EEG = abs(EEG);
    
PeaksIdx  = find([diff(EEG); 0] < 0 & [0; diff(EEG)] > 0);
TP = double([T(PeaksIdx) EEG(PeaksIdx)]);
x = linspace(T(1),T(end),round((T(end)/1e6-T(1)/1e6)*down_sFreq));
y = interp1(TP(:,1),TP(:,2),x);
%
y = conv(y,hanning(smooth_win_pts)/sum(hanning(smooth_win_pts)));
y = y(ceil(smooth_win_pts/2):(end - ceil(smooth_win_pts/2)));
TP = [x(:) y(:)];
clear x y;

if isnan(thresh_uVolts)
    % Automatically choose the motion threshold. - largest value between
    % The median of the convolved data ( presuming his most common motion 
    %  during sleep is stillness - reasonable) and the minimum peak height in convolved movement
    %  assuming that smallest peak in the smoothed data represents the minimal jitter
    %  in the data.
    thresh_uVolts = max([nanmin(TP(:,2))*2.5 nanmedian(TP(:,2))*1.1]); % add a little slop for micro movements.
    disp(['Automatic EMG detectiom threshold set as ' num2str(thresh_uVolts)])
end

if plot_it
    h1 = subplot(2,1,1);
    % plot position and movement by time
    plot(T/(1e6*60),EEG,'b')
    hold on
    plot(TP(:,1)/(1e6*60),TP(:,2),'r','LineWidth',2)
    title('EMG')
    ylabel('uVolts')
    xlabel('time minutes')
    axis tight
    subplot(2,1,2)
    % Histogram position.
    hist(TP(:,2),100)
    hold on
    ylabel('count')
    xlabel('sum of abs diff of peak heights')
    % - 
    if isempty(thresh_uVolts)
        title('Choose threshold')
        [thresh_uVolts, y] = ginput(1);
    end

    title('Motion Threshold')
    % plot the threshold
    a = axis;
    plot([thresh_uVolts thresh_uVolts],[a(3) a(4)],'r:');
end
SE_times_above_usec = [];
SE_times_below_usec = [];
% Do this separately for each epoch under consideration.
for iEpoch = 1:size(epoch_times,1)

    st_ix = find(TP(:,1)>epoch_times(iEpoch,1),1,'first');
    ed_ix = find(TP(:,1)<epoch_times(iEpoch,2),1,'last');
    % DETERMINE THE INTERVALS
    if ed_ix > st_ix
        [above_se, below_se] = find_intervals(TP(st_ix:ed_ix,:) ,thresh_uVolts, thresh_uVolts *.5,0.5e6,3e6);
        SE_times_above_usec  = [SE_times_above_usec; above_se];
        SE_times_below_usec  = [SE_times_below_usec; below_se];
    end
end

if plot_it
    subplot(h1)
    hold on
    patch_intervals(SE_times_above_usec/(1e6*60),'b',.2)
    patch_intervals(SE_times_below_usec/(1e6*60),'r',.2)
end
