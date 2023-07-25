function View_EEG(in_array, windowsize, ylimit, staggar)
% Look at a moving window of EEG
% 
% INPUT:
%       crtsd  = cell array of tsds to plot. If the tsd is simply a list of
%                timestamps(as ts object) then a raster is printed. If it is
%                a tsd then the data is plotted.
%
%   windowsize = size of the moving window (in seconds). Default is 1sec.
%
%      ylimit  = size of the y axes on the plot(+ and - y limit)
%
% function View_EEG(in_array, windowsize, ylimit)

% cowen Mon Jul  5 15:56:39 1999
if nargin == 1
  windowsize = 1; %sec
  ylimit = 300; % Y axis
  staggar = 50; % vertical spacing between plots
elseif nargin == 2
  ylimit = 300;
  staggar = 50; % vertical spacing between plots
elseif nargin == 3
  staggar = 50; % vertical spacing between plots
end

if ~iscell(in_array)
  crtsd_array{1} = in_array;
  clear in_array
else 
  crtsd_array = in_array;
  clear in_array
end

windowsize = 10000*windowsize; % Convert seconds to timestamps
for ii = 1:length(crtsd_array)
  if ~isempty(crtsd_array{ii})
    tstart = StartTime(crtsd_array{ii});     
    tend = EndTime(crtsd_array{ii});
    break;
  end
end
% Better to do this as an infinite loop and slide back and
% forth. Later.
figure
startpt = tstart;
Plot_tsds(crtsd_array, startpt,windowsize,ylimit,staggar)

%startpt = startpt + windowsize
movesize = round(windowsize/2);

while (1)
  gi = ginput(1);
  if abs(gi(2)) > ylimit 
    disp('Bye');
    return;
  elseif gi(1) < (startpt + round(windowsize/2))
    startpt = startpt - movesize;
    if startpt < tstart
      startpt = tstart;
    end
    disp('back');    
  else  
    disp('forward');
    startpt = startpt + movesize;
    if startpt > tend-windowsize
      startpt = tend-windowsize;
      disp('At end of record');
    end
  end
  Plot_tsds(crtsd_array, startpt, windowsize, ylimit, staggar)
end
