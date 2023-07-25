function [ctsa_spikes,mean_freq] = Gen_spike_trains(mean_frequencies,duration,refractory_per,model)
% generate random spike train
% INPUT:   mean_frequencies = vector of lenth ncells that contains the firing rate
%          duration = (seconds)
%          refractory_per = refractory period (seconds,(i.e. .01 = 10msec)
%          model = model of spike trains(gaussian, poisson, etc..)
%          sigma = the sigma of the gaussian noise applied to the data.
%
%
% OUTPUT:
%  ctsa_spikes = tsarray of spikes
%  rates = the rates used to generate each cells

% cowen 
if nargin < 3
  refractory_per = .003; % 3 msec seems reasonable
  model = 'poisson';
elseif nargin < 4 
  model = 'poisson';
elseif nargin == 1
  error('You are missing some parameters')
end
ncells = length(mean_frequencies);

for cellno = 1:ncells
  % Generate the spikes for this cell
  [ctsa_spikes{cellno}] = ts(Artificial_spikes(mean_frequencies(cellno),duration,refractory_per,model,'.1msec'));
end
