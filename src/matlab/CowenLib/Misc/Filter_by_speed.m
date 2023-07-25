function [spikes, times] = Filter_by_speed(spikes, times,threshold,x_tsd,y_tsd,plotit)
%
% Remove columns in the spikes and times matrices that correspond to speeds
% above the passed threshold
%
% INPUT:
%  spikes: cell by time matrix
%  times:  1 by time matrix of timestamps for each col in spikes
%  threshold: cutoff speed as a fraction of the maximum speed.
%   if the threshold is negative, then only columns where the rat ran
%   below that amount will be kept
%   if the threshold is positive, then only the columns where the rat
%   ran faster than that speed will be kept.
%  x_tsd, y_tsd = tsd objects of position.
%  plotit = a flag that specifies whether to show a plot of the
%   postion, speed and threshold. Use this to determine the threshold.
%
% OUTPUT:
%  the spikes and times matrices with the sub threshold columns removed.
%  EXCEPTION: If only one output is specified, only the indices of the
%    columns that are to be KEPT(below threshold) is returned. 
%
% NOTE: Assumes the position data has already been reasonably
% smoothed. Some additional smoothing is done as well.

% cowen Sat Sep 11 16:50:23 1999
%
if nargin == 5
  plotit = 0;
end

% The speed is the diff in the coordinates.
% This only works if the data has been sufficiently filtered.
POS.speed = abs([0; sqrt(diff(Data(x_tsd)).^2 + diff(Data(y_tsd)).^2)]);
POS.speed = POS.speed / max(POS.speed); % normalize value to be between 0 and 1.
POS.smoothspeed = Smooth_vel(POS.speed,300);
POS.smoothspeed = POS.smoothspeed / max(POS.smoothspeed);
% Smooth the data so it is easier to work with. 
POS.times = Range(x_tsd,'ts'); % The timestamps for each velocity point
median_speed = median(POS.speed); 
if(length(POS.times(find(POS.times < 1))) > 0)
  error('wierd times. recheck.')
end

if threshold < 0
  % Find the indices of the periods of slow motion
  times_to_keep = POS.times(find(POS.smoothspeed < abs(threshold)));
else
  % Filter the indices of the periods of fast motion
  times_to_keep = POS.times(find(POS.smoothspeed > threshold));
end

disp(['Found ' num2str(length(times_to_keep)) ' good bins out of ' num2str(length(POS.times))])

idx_to_keep = zeros(length(times_to_keep),1);

for ii = 1:length(times_to_keep)
  idx_to_keep(ii) = binsearch(times,times_to_keep(ii));
end
length(idx_to_keep)
idx_to_keep = unique(idx_to_keep);
length(idx_to_keep)
% if only one argout is specified, just return the indices of the 
% keepers(the ones within the threshold.
if nargout == 1
  spikes = idx_to_keep;
  return
end

% Remove the columns
%spikes(:,idx_to_kill) = []; % NEVER DO THIS, IT TAKES FOREVER!
times = times(idx_to_keep);
spikes = spikes(:,idx_to_keep);

if plotit
  % Now check the results
  figure;hold on
  plot(Range(x_tsd,'ts'),Data(x_tsd),'b')
  plot(Range(y_tsd,'ts'),Data(y_tsd),'r')
  plot(POS.times,POS.smoothspeed*200,'m')
  plot(POS.times,POS.speed*200,'k')
  plot(times,ones(1,length(times))*median(Data(x_tsd)),'r.')
  plot([times(1) times(end)], [abs(threshold)*200 abs(threshold)*200],'c')
  legend('x','y','smoothspd','spd','keepers')
  drawnow
end

