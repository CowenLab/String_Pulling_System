function [SE_times_above_usec SE_times_below_usec thresh_uVolts TP] = ...
    Spindle_times_rat(EEG_file,epoch_times,thresh_uVolts);
% function [SE_times_above_usec SE_times_below_usec thresh_uVolts cemg] = ...
%     Spindle_times_rat(EMG_file,epoch_times,thresh_uVolts);
%
% Determine the spindle periods in rat data - 
%
%  INPUT:
%   EEG_file = filename of CSC EEG file.
%   epoch_times = usec of start end times for epoch to analyze: TIMES ARE
%     ASSUMED TO BE IN USEC.
%   thresh_uVolts - voltage to consider as an emg burst.
%   smooth_size_sec = width of hanning in seconds used to smooth position
%     data. Default is 1 second.
%
% OUTPUT: 
%   the periods of spindles (e.g. sleep as opposed to behavior) usec
%   the periods of non-spindles within the specified epochs. usec
%   the threshold used for detection
%   the convolved eeg power data used for detection.
% 
% if no outputs specified, it will plot out the position and smoothed
% EEG data.
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
smooth_win_sec = 0.3;
sFreq = 200;
down_sFreq = 20;
smooth_win_pts = down_sFreq*smooth_win_sec;
% load EEG
if isstr(EEG_file)
    [T, EEG] = Read_CR_files(EEG_file, sFreq, epoch_times);%, {'highpass'}, {20});
    % recenter
    EEG = EEG - mean(EEG);
    N = 4;                    % Order of the filter
    ripple = .1;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Filter the data.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [B,A] = cheby1(4, .1, [12 17]/(sFreq/2));
    EEG = filtfilt(B,A,EEG);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Do a slow filter on this (I found that a later convolution works
    % slightly better.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %    [B,A] = cheby1(4, .1,2 /(sFreq/2),'low');
    %    EEG2 = filtfilt(B,A,abs(EEG));
else
    %Assume the user passed in a matrix of Time (col1) and Data (col2) of
    %filtered EEG (200Hz). Timestamps in usec.
    T = EEG_file(:,1);
    sFreq = 1/(mean(diff(T))/1e6)
    EEG = EEG_file(:,2);
    clear EEG_file;
    pack
end
% Generate a measure of movement by adding the movement at each point in the 
%  x dimension to the movement at each point in the y dimension.
EEG = abs(EEG);
PeaksIdx  = find([diff(EEG); 0] < 0 & [0; diff(EEG)] > 0);
TP = double([T(PeaksIdx) EEG(PeaksIdx)]);
x = linspace(T(1),T(end),round((T(end)/1e6-T(1)/1e6)*down_sFreq));
y = interp1(TP(:,1),TP(:,2),x);
%
%y = conv(y,hanning(smooth_win_pts)/sum(hanning(smooth_win_pts)));
%y = y(ceil(smooth_win_pts/2):(end - ceil(smooth_win_pts/2)));
y = convn(y',hanning(smooth_win_pts)/sum(hanning(smooth_win_pts))','same');
TP = [x(:) y(:)];
clear x y;

if isnan(thresh_uVolts)
    % Automatically choose the motion threshold.
    thresh_uVolts = prctile(TP(:,2),90); % 
    disp(['Automatic detectiom threshold set as ' num2str(thresh_uVolts)]);
end

if plot_it
    h1 = subplot(2,1,1);
    % plot position and movement by time
    plot(T/(1e6),EEG,'b')
    hold on
    plot(TP(:,1)/(1e6),TP(:,2),'r','LineWidth',2)
    title('EEG')
    ylabel('uVolts')
    xlabel('time sec')
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

    title('Threshold')
    % plot the threshold
    a = axis;
    plot([thresh_uVolts thresh_uVolts],[a(3) a(4)],'r:');
end
% Find the spindles
SE_times_above_usec = [];
SE_times_below_usec = [];
% Do the detection separately for each epoch under consideration.
for iEpoch = 1:size(epoch_times,1)
    st_ix = find(TP(:,1)>epoch_times(iEpoch,1),1,'first');
    ed_ix = find(TP(:,1)<epoch_times(iEpoch,2),1,'last');
    % DETERMINE THE INTERVALS
    if ed_ix > st_ix
        [above_se, below_se] = find_intervals(TP(st_ix:ed_ix,:) ,thresh_uVolts, thresh_uVolts *.5,0.4e6,.5e6);
        SE_times_above_usec  = [SE_times_above_usec; above_se];
        SE_times_below_usec  = [SE_times_below_usec; below_se];
    end
end

if plot_it
    subplot(h1)
    hold on
    patch_intervals(SE_times_above_usec/(1e6),'b',.2);
    patch_intervals(SE_times_below_usec/(1e6),'r',.2);
end
