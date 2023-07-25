function [x_tsd,y_tsd] = Load_position(data_dir,pos_file,smooth_it)
% Load position data and smooth it if it hasn't been smoothed already.
%
% cowen 2/1/00
if nargin == 2
  smooth_it = 0;
end

if fopen(fullfile(data_dir,pos_file))==-1
  pos_file
  error('Position file not found')
end

if strcmp(pos_file(end-2:end),'mat')
  % All the smoothing and partitioning have already been done
  load(fullfile(data_dir,pos_file))
  try
    x_tsd{1};y_tsd{1};
  catch
    error('The assumed x_tsd or y_tsd variables were not found')
  end
elseif strcmp(pos_file(end-4:end),'ascii')
  times = Load_times(fullfile(data_dir,'epoch_times.ascii'));
  [Xtsd,Ytsd] = LoadPosition(fullfile(data_dir,pos_file));
  [Xtsd,Ytsd] = CleanTrackerData(Xtsd,Ytsd);
  if smooth_it
    Xtsd = SmoothTsd(Xtsd,200);
    Ytsd = SmoothTsd(Ytsd,200);
    fname = 'smooth_xy_tsd.mat';
  else
    fname = 'xy_tsd.mat';
  end
  % Chop up the data by epoch
  for epoch = 1:size(times,1)
    start_time   = times(epoch, 1);
    end_time     = times(epoch, 2);
    x_tsd{epoch} = Restrict(Xtsd, start_time, end_time);
    y_tsd{epoch} = Restrict(Ytsd, start_time, end_time);
    fprintf('.')
  end
  save(fullfile(data_dir,fname), 'x_tsd', 'y_tsd');
end
