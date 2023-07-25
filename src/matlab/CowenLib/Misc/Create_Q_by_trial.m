function [T] = Create_Q_by_trial(ts_array,dt_msec,tessel_params,varargin)
% Create a matrix that has the Q matrix for each trial. 
% The identity of each bin is indicated by trial_id which tells which trial the bin 
% came from.
% The identity of each class is indiceated by the vector class_id
% T is a timebin X cell matrix.
% If dt_msec is an empty matrix, then each trial is treated as one bin and the spike count is divided
% by the time per trial to yield a firing rate.
% this seems to be a modified tsd object.
% 
% INPUT
%   ts_array = a ts array of cells and spike times
%   dt_msec = the bin size in msec. If 0, then binning will be done by trial.
%   tessel_params = CELL ARRAY. if you choose to tesselate or preprocess the Q matrix in some
%        fashon, tessel_params is a vector of parameters. If you don't want to tesselate
%        then just make this an empty matrix ([] or cell array). The permitted parameters are as follows:
%              tessel_params{1} = rf_size  (receptive field size-- or the degree of tesselation)
%              tessel_params{2} = step     (amount of shift in each tesselation)
%              tessel_params{3} = method   (a string that specifies the method of tesselation ('csr','by_col')
%   vararagin = each one is a matrix (trial X start and end times) that contains the 
%      start and end times for each class. You can specify as many classes as you like.
%
% OUTPUT
%   T.T = a big ass matrix (bin X Cell) that contains the number of spikes per bin
%   T.timestamps = the timestamp for each row in T.T.
%   T.duration_sec = a vector of length rows in T.T that contains the duration in sec of each bin in T.T.
%                T.T/repmat(T.duration,1,Cols(T.T)) will give you firing rates in Hz. This 
%                is only provided if binning is done by trial, otherwise, all the bins will be 
%                of length dt_msec.
%   T.trial_id = a vector that tells which trial each bin in T belongs
%   T.class_id = a vector that tells which class each bin in T belongs
%   T.cell_id  = a vector that idetifies each column in T. For instance, if
%                you decide to tesselate the data with a rf of 3, then the 
%                cell_id will be 1 1 1 2 2 2 3 3 3 etc...

% cowen
if nargin == 3
  error('You need to specify the start and end times for each time in a class')
end
ncells = length(ts_array);
nclasses = length(varargin);
T.T = [];
T.duration_sec = [];
T.trial_id = [];
T.class_id = [];
T.cell_id = [];

if ~isempty(tessel_params)
  tessel_data = 1;
  if length(tessel_params)~=3
    error('invalid parameter cell array')
  end
  step = tessel_params{1};
  rf_size = tessel_params{2};
  method = tessel_params{3};
  a = repmat(1:ncells,rf_size,1);
  T.cell_id = a(:)';
else 
  tessel_data = 0;
  T.cell_id = 1:ncells;
end

class_and_times = [];
for cls = 1:nclasses
  class_and_times = [class_and_times;cls*(ones(Rows(varargin{cls}),1)),varargin{cls}];
end
% sort on start_time
class_and_times = sortrows(class_and_times,2);
ntrials = Rows(class_and_times);
trial_class_and_times = [[1:ntrials]',class_and_times];
% Now sort by class and time as this makes it easier to visualize class differences
trial_class_and_times = sortrows(trial_class_and_times,[2 3]);

if isempty(dt_msec) | isinf(dt_msec) | dt_msec == 0
  % treat each trial as one bin
  T.T = zeros(ntrials,ncells);
  T.trial_id = zeros(ntrials,1);
  T.class_id = zeros(ntrials,1);
  T.timestamps = zeros(ntrials,2);
  n_spikes_per_cell = zeros(1,ncells);
  
  T.duration_sec = [(trial_class_and_times(:,4) - trial_class_and_times(:,3))/10000];
  for idx = 1:ntrials
    % The start and end time for this trial.
    the_times = trial_class_and_times(idx,3:4);
    for cellid = 1:ncells
      % Get the firing rates for each trial to door and to the curtain
      n_spikes_per_cell(cellid) = length(Data(Restrict(ts_array{cellid},the_times(1),the_times(2))));
      % n_spikes_per_trial(trialno,cellid) = length(Data(Restrict(ts_array{cellid},all_times(trialno,1),all_times(the_trial,2))));
    end
    T.T(idx,:) = n_spikes_per_cell;
    T.trial_id(idx)=trial_class_and_times(idx,1);
    T.class_id(idx)=trial_class_and_times(idx,2);
    T.timestamps(idx,:) = the_times;
  end
else
  % 
  for idx = 1:ntrials
    the_times = trial_class_and_times(idx,3:4);
    M = MakeQfromS(ts_array,dt_msec*10,'T_start',the_times(1),'T_end',the_times(2),'ProgressBar','');
    tT = Data(M);
    T.times_msec = Range(M,'ms');
    if tessel_data
      tT = Tessel_matrix(tT,step,rf_size,method);
    end
    nbins = Rows(tT);
    T.trial_id = [T.trial_id;ones(nbins,1)*trial_class_and_times(idx,1)];
    T.class_id = [T.class_id;ones(nbins,1)*trial_class_and_times(idx,2)];
    T.T = [T.T;tT];
    fprintf('.')
  end
  T.duration_sec = ones(length(T.trial_id),1)*dt_msec*1000; % bin duration in seconds.
end
fprintf('\n')
