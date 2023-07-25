function timestamps = Gen_spikes(freq,duration_sec,refractory_per,model,out_units)
% generate random spike train
% INPUT:   freq = firing rate Hz
%          duration_sec = (seconds)
%          refractory_per = refractory period (seconds,(i.e. .01 - 10msec)
%          model = model of spike trains(gaussian, poisson, etc..)
%          out_units = can specify output units ('.1msec' or '1msec')

% OUTPUT:  timestamps for each spike

% cowen
if nargin == 2
  isi = 0;
end
if nargin == 3
  out_units= '.1msec';
end			
nSpikes = round(freq * duration_sec);
switch out_units
case {'1msec' , 'msec'}
  total_time = duration_sec*1000;  % msec
  refractory_per = refractory_per*1000;
case '.1msec'
  total_time = duration_sec*10000; % timestamps
  refractory_per = refractory_per*10000;
otherwise
  error('improper time units')
end	
if refractory_per == 0
  timestamps = sort(round(rand(1,nSpikes)*total_time)); % timestamps for each spike
else 
  % Remove the spikes that fall within the refractory period and then add in 
  % an amount equal to the number removed in order to maintain the user specified 
  % frequency.
  l = nSpikes; % number of deleted spikes
  timestamps = [];
  while l > 0
    switch model
    case 'poisson'
      timestamps = sort([timestamps round(rand(1,l)*total_time)]); % timestamps for each spike
    case 'gaussian'
      timestamps = sort([timestamps round(randn(1,l)*total_time)]); % timestamps for each spike
    case 'real_sleep'
      % Load in real data from a real rat during real sleep.
    case 'real_waking'
    otherwise
      error('Invalid model')
    end
    d = diff(timestamps);
    idx = find(d<refractory_per); % find spikes within refractory period
    l = length(idx); % number to wipe out
    timestamps(idx) = [];
    % fprintf('%d,',l)
  end		
end	
timestamps = unique(timestamps(:));