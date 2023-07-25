function [SE_times_above_usec SE_times_below_usec thresh_movement_pixels cmvt] = ...
    movement_times(TXY_text_file,epoch_times,thresh_movement_pixels,smooth_size_sec);
%function se_times = movement_times(TXY_text_file,epoch_times,thresh_movement_pixels,smooth_size_sec);
%
% determine periods of movement in the data. - useful for sleep analysis.
%
%  INPUT:
%   TXY_text_file = filename of the text (time, x, y...) file: TIMES ARE
%     ASSUMED TO BE IN USEC.
%   epoch_times = usec of start end times for epoch to analyze: TIMES ARE
%     ASSUMED TO BE IN USEC.
%   thresh_movement_pixels = threshold to consider as motion.
%     if empty, then allow the user to choose.
%     if nan, then use an automatic detection (using median of the movement
%     - presumes the most common movement will be 'stillness'.
%   smooth_size_sec = width of hanning in seconds used to smooth position
%     data. Default is 1 second.
%
% OUTPUT: 
%   the periods of motion. usec
%   the periods of stillness within the specified epochs. usec
%   the threshold used for detection
%   the convolved position data used for detection.
% 
% if no outputs specified, it will plot out the position and smoothed
% position data.
% 
% cowen 2006
plot_it = 1;
if nargout == 0
    plot_it = 1;
end
if nargin < 3
    thresh_movement_pixels = [];
    plot_it = 1;
end
if nargin < 4
    smooth_size_sec = 1; % width of the hanning window for smoothing motion.
end
% load position
[t_x_y, sFreq]= Load_position_text_file(TXY_text_file,epoch_times);
if isempty(epoch_times)
    epoch_times = [t_x_y(1,1) t_x_y(end,1) ];
end
% Generate a measure of movement by adding the movement at each point in the 
%  x dimension to the movement at each point in the y dimension.
mvt = [0; sum(abs(diff(t_x_y(:,[2 3])))')'];
% smooth
smooth_size_samples = round(sFreq*smooth_size_sec); % size of hanning
cmvt = convn(mvt,hanning(smooth_size_samples),'same');
if isnan(thresh_movement_pixels)
    % Automatically choose the motion threshold. - largest value between
    % The median of the convolved data ( presuming his most common motion 
    %  during sleep is stillness - reasonable) and the minimum peak height in convolved movement
    %  assuming that smallest peak in the smoothed data represents the minimal jitter
    %  in the data.
    PeaksIdx  = find([diff(cmvt); 0] < 0 & [0; diff(cmvt)] > 0);
    thresh_movement_pixels = max([nanmin(cmvt(PeaksIdx))*2.5 nanmedian(cmvt)*1.1]); % add a little slop for micro movements.
    disp(['Automatic motion detectiom threshold set as ' num2str(thresh_movement_pixels)])
end

if plot_it
    h1 = subplot(4,1,1:3);
    % plot position and movement by time
    plot(t_x_y(:,1)/(1e6*60),mvt-min(mvt),'m')
    hold on
    plot(t_x_y(:,1)/(1e6*60),cmvt-min(cmvt),'r','LineWidth',2)
    plot(t_x_y(:,1)/(1e6*60),t_x_y(:,2) - mean(t_x_y(:,2)),'b')
    plot(t_x_y(:,1)/(1e6*60),t_x_y(:,3) - mean(t_x_y(:,3)),'g')
    title('movement in pixels')
    ylabel('Z')
    xlabel('time minutes')
    subplot(4,1,4)
    % Histogram position.
    hist(cmvt(find(cmvt>0)),40)
    hold on
    ylabel('count')
    xlabel('sum of abs diff of position in x and y')
    % - 
    if isempty(thresh_movement_pixels)
        title('Choose threshold')
        [thresh_movement_pixels, y] = ginput(1);
    end

    title('Motion Threshold')
    % plot the threshold
    a = axis;
    plot([thresh_movement_pixels thresh_movement_pixels],[a(3) a(4)],'r:');
end
SE_times_above_usec = [];
SE_times_below_usec = [];
% Do this separately for each epoch under consideration.
for iEpoch = 1:size(epoch_times,1)
    %    st_ix = binsearch(t_x_y(:,1), epoch_times(iEpoch,1)); % much faster than find
    %    ed_ix = binsearch(t_x_y(:,1), epoch_times(iEpoch,2)); % much faster than find
    % Binseach bombs in some cases.
    st_ix = find(t_x_y(:,1) >= epoch_times(iEpoch,1),1,'first');
    ed_ix = find(t_x_y(:,1) < epoch_times(iEpoch,2),1,'last');
    % DETERMINE THE INTERVALS
    [above_se, below_se] = find_intervals([t_x_y(st_ix:ed_ix,1) cmvt(st_ix:ed_ix)],thresh_movement_pixels,thresh_movement_pixels *.5,0.5e6,3e6);
    SE_times_above_usec  = [SE_times_above_usec; above_se];
    SE_times_below_usec  = [SE_times_below_usec; below_se];
end

if plot_it
    subplot(h1)
    hold on
    patch_intervals(SE_times_above_usec/(1e6*60),'b',.2)
    patch_intervals(SE_times_below_usec/(1e6*60),'r',.2)
    axis tight
end

if nargout == 4 
    % If the caller wants it, give them the time and convolved position data.
    cmvt = [t_x_y(:,1) cmvt(:)];
end